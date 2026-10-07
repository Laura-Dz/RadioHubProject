#!/usr/bin/env python3
"""
RadioHub Frame-Preserving Stream Encryptor.
Reads MP3 bytes from stdin (from Liquidsoap), encrypts the audio payload
of each MPEG frame using AES-128-CTR with the station's secret key while
preserving the 4-byte MPEG sync header, and pushes the encrypted stream to Shoutcast.

This allows Shoutcast to maintain frame synchronization (never dropping the source),
while guaranteeing that anyone listening directly to Shoutcast only hears scrambled
cipher noise. Only the Django backend with the matching key can decrypt the stream.
"""
import os
import sys
import socket
import base64
import urllib.request
import urllib.error
from pathlib import Path
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend

KEY_FILE = Path(os.environ.get('AES_KEY_FILE', '/opt/radio/current.key'))
if not KEY_FILE.exists():
    local_key = Path(__file__).resolve().parent / 'current.key'
    if local_key.exists():
        KEY_FILE = local_key

DJANGO_API_URL = os.environ.get('DJANGO_API_URL', '')
RADIO_ID = os.environ.get('RADIO_ID', 'radio_1790489454722')
STATION_API_KEY = os.environ.get('STATION_API_KEY', '')

SHOUTCAST_HOST = os.environ.get('SHOUTCAST_HOST', '127.0.0.1')
SHOUTCAST_PORT = int(os.environ.get('SHOUTCAST_PORT', 8001))
SOURCE_PASSWORD = os.environ.get('SHOUTCAST_SOURCE_PASSWORD', 'shoutcast_source_password')
MOUNT = os.environ.get('SHOUTCAST_MOUNT', '/stream/1')
ICY_NAME = os.environ.get('ICY_NAME', 'Radio Maria Cameroon')
ICY_GENRE = os.environ.get('ICY_GENRE', 'Various')
BITRATE = int(os.environ.get('BITRATE', 320))

NONCE = b'\x00' * 16


def load_key() -> bytes:
    """Loads the 16-byte AES key."""
    if DJANGO_API_URL and STATION_API_KEY:
        try:
            url = f"{DJANGO_API_URL.rstrip('/')}/api/internal/stream-key/{RADIO_ID}/"
            req = urllib.request.Request(
                url,
                data=b"",
                headers={
                    "X-Station-Key": STATION_API_KEY,
                    "User-Agent": "RadioHub-Encoder/1.0",
                },
            )
            opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
            with opener.open(req, timeout=10) as resp:
                if resp.status == 200:
                    key = resp.read()
                    if len(key) == 16:
                        print(f"[encrypt_and_forward] Key loaded dynamically from Django for '{RADIO_ID}'", file=sys.stderr)
                        return key
        except Exception as e:
            print(f"[encrypt_and_forward] Warning: Could not fetch key from Django ({e}); trying local key...", file=sys.stderr)

    if KEY_FILE.exists():
        key = KEY_FILE.read_bytes()
        if len(key) == 16:
            print(f"[encrypt_and_forward] Key loaded from local file: {KEY_FILE}", file=sys.stderr)
            return key
        raise ValueError(f"Local key file {KEY_FILE} must be 16 bytes, got {len(key)}")

    raise RuntimeError(f"Unable to load AES key for '{RADIO_ID}'.")


def get_mp3_frame_size(b: bytes, offset: int = 0) -> int | None:
    """Calculate the byte size of an MPEG-1/2 Layer 3 audio frame from its 4-byte header."""
    if len(b) - offset < 4:
        return None
    if b[offset] != 0xFF or (b[offset + 1] & 0xE0) != 0xE0:
        return None

    version_bits = (b[offset + 1] >> 3) & 0x03
    layer_bits = (b[offset + 1] >> 1) & 0x03
    bitrate_idx = (b[offset + 2] >> 4) & 0x0F
    sample_rate_idx = (b[offset + 2] >> 2) & 0x03
    padding = (b[offset + 2] >> 1) & 0x01

    if layer_bits != 1:  # Layer 3
        return None

    # MPEG-1 Layer 3
    if version_bits == 3:
        bitrates = [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0]
        sample_rates = [44100, 48000, 32000, 0]
        if bitrate_idx >= len(bitrates) or sample_rate_idx >= len(sample_rates):
            return None
        br = bitrates[bitrate_idx] * 1000
        sr = sample_rates[sample_rate_idx]
        if sr == 0 or br == 0:
            return None
        return int((144 * br) // sr) + padding

    # MPEG-2 / 2.5 Layer 3
    elif version_bits in (0, 2):
        bitrates = [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0]
        sample_rates = [22050, 24000, 16000, 0] if version_bits == 2 else [11025, 12000, 8000, 0]
        if bitrate_idx >= len(bitrates) or sample_rate_idx >= len(sample_rates):
            return None
        br = bitrates[bitrate_idx] * 1000
        sr = sample_rates[sample_rate_idx]
        if sr == 0 or br == 0:
            return None
        return int((72 * br) // sr) + padding

    return None


def connect_to_shoutcast() -> socket.socket:
    sock = socket.create_connection((SHOUTCAST_HOST, SHOUTCAST_PORT), timeout=10)
    if SHOUTCAST_PORT == 8001:
        sock.sendall(f"{SOURCE_PASSWORD}\r\n".encode())
        resp = sock.recv(1024)
        if b"OK" in resp:
            headers = (
                f"icy-name:{ICY_NAME}\r\n"
                f"icy-genre:{ICY_GENRE}\r\n"
                f"icy-br:{BITRATE}\r\n"
                f"icy-pub:0\r\n\r\n"
            ).encode()
            sock.sendall(headers)
        else:
            raise RuntimeError(f"Shoutcast source handshake failed: {resp}")
    else:
        auth = base64.b64encode(f"source:{SOURCE_PASSWORD}".encode()).decode()
        req = (
            f"POST {MOUNT} HTTP/1.0\r\n"
            f"Authorization: Basic {auth}\r\n"
            f"User-Agent: Liquidsoap-Encryptor/1.0\r\n"
            f"Content-Type: audio/mpeg\r\n"
            f"icy-name: {ICY_NAME}\r\n"
            f"icy-genre: {ICY_GENRE}\r\n"
            f"icy-bitrate: {BITRATE}\r\n"
            f"icy-pub: 0\r\n\r\n"
        ).encode()
        sock.sendall(req)
    return sock


def xor_payload(payload: bytes, keystream: bytes) -> bytes:
    L = len(payload)
    if L == 0:
        return b""
    return (int.from_bytes(payload, "big") ^ int.from_bytes(keystream[:L], "big")).to_bytes(L, "big")


def main():
    key = load_key()
    cipher = Cipher(
        algorithms.AES(key),
        modes.CTR(NONCE),
        backend=default_backend(),
    )
    keystream = cipher.encryptor().update(b"\x00" * 4096)

    sock = connect_to_shoutcast()
    buffer = bytearray()

    try:
        while True:
            chunk = sys.stdin.buffer.read(4096)
            if not chunk:
                break
            buffer.extend(chunk)

            while True:
                if len(buffer) < 4:
                    break

                # Find MPEG sync word (0xFF, 0xEx)
                if buffer[0] != 0xFF or (buffer[1] & 0xE0) != 0xE0:
                    idx = -1
                    for i in range(1, len(buffer) - 1):
                        if buffer[i] == 0xFF and (buffer[i + 1] & 0xE0) == 0xE0:
                            idx = i
                            break
                    if idx != -1:
                        # Forward any unaligned/metadata bytes directly
                        sock.sendall(bytes(buffer[:idx]))
                        buffer = buffer[idx:]
                    else:
                        if buffer[-1] == 0xFF:
                            sock.sendall(bytes(buffer[:-1]))
                            buffer = buffer[-1:]
                        else:
                            sock.sendall(bytes(buffer))
                            buffer.clear()
                        break

                frame_size = get_mp3_frame_size(buffer, 0)
                if frame_size is None or len(buffer) < frame_size:
                    # Incomplete frame, wait for more data
                    break

                # Extract frame
                hdr = bytes(buffer[:4])
                payload = bytes(buffer[4:frame_size])
                del buffer[:frame_size]

                # Encrypt payload per-frame, preserve header
                enc_payload = xor_payload(payload, keystream)
                sock.sendall(hdr + enc_payload)

    finally:
        sock.close()


if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(f'encrypt_and_forward error: {e}', file=sys.stderr)
        sys.exit(1)
