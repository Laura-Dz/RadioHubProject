#!/usr/bin/env python3
"""
Reads MP3 bytes from stdin, AES-128-CBC encrypts them,
and pushes the encrypted stream to Shoutcast as a source.

Shoutcast relays encrypted bytes without knowing or caring.
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

# Remote Django key management configuration
DJANGO_API_URL = os.environ.get('DJANGO_API_URL', '')  # e.g., 'https://radiohub.example.com' or 'http://127.0.0.1:8000'
RADIO_ID = os.environ.get('RADIO_ID', 'station_1')
STATION_API_KEY = os.environ.get('STATION_API_KEY', '')

SHOUTCAST_HOST = os.environ.get('SHOUTCAST_HOST', '127.0.0.1')
SHOUTCAST_PORT = int(os.environ.get('SHOUTCAST_PORT', 8000))
SOURCE_PASSWORD = os.environ.get('SHOUTCAST_SOURCE_PASSWORD', 'shoutcast_source_password')
MOUNT = os.environ.get('SHOUTCAST_MOUNT', '/stream')
ICY_NAME = os.environ.get('ICY_NAME', 'RadioHub Station')
ICY_GENRE = os.environ.get('ICY_GENRE', 'Various')
BITRATE = int(os.environ.get('BITRATE', 320))

IV = b'\x00' * 16  # static IV — same IV must be used by Django


def load_key() -> bytes:
    """
    Loads the 16-byte AES key.
    1. If DJANGO_API_URL and STATION_API_KEY are configured, fetches the key
       dynamically from the central Django server over HTTPS.
    2. Otherwise (or if Django is unreachable), falls back to the local key file.
    """
    if DJANGO_API_URL and STATION_API_KEY:
        try:
            url = f"{DJANGO_API_URL.rstrip('/')}/api/internal/stream-key/{RADIO_ID}/"
            req = urllib.request.Request(
                url,
                data=b"",  # POST
                headers={
                    "X-Station-Key": STATION_API_KEY,
                    "User-Agent": "RadioHub-Encoder/1.0",
                },
            )
            # Avoid system proxies intercepting internal/localhost connections
            if "127.0.0.1" in url or "localhost" in url:
                opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
            else:
                opener = urllib.request.build_opener()

            with opener.open(req, timeout=10) as resp:
                if resp.status == 200:
                    key = resp.read()
                    if len(key) == 16:
                        print(f"[encrypt_and_forward] Key loaded dynamically from Django for station '{RADIO_ID}'", file=sys.stderr)
                        return key
                    else:
                        print(f"[encrypt_and_forward] Warning: Django returned invalid key length ({len(key)} bytes)", file=sys.stderr)
        except Exception as e:
            print(f"[encrypt_and_forward] Could not fetch key from Django ({e}); trying local fallback...", file=sys.stderr)

    if KEY_FILE.exists():
        key = KEY_FILE.read_bytes()
        if len(key) == 16:
            print(f"[encrypt_and_forward] Key loaded from local file: {KEY_FILE}", file=sys.stderr)
            return key
        raise ValueError(f"Local key file {KEY_FILE} must be 16 bytes, got {len(key)}")

    raise RuntimeError(
        f"Unable to load AES key for station '{RADIO_ID}'. "
        f"Django URL: '{DJANGO_API_URL}', Local file: '{KEY_FILE}'."
    )



def build_http_source_headers() -> bytes:
    auth = base64.b64encode(
        f'source:{SOURCE_PASSWORD}'.encode()
    ).decode()
    return (
        f'POST {MOUNT} HTTP/1.0\r\n'
        f'Authorization: Basic {auth}\r\n'
        f'User-Agent: Liquidsoap-Encryptor/1.0\r\n'
        f'Content-Type: audio/mpeg\r\n'
        f'icy-name: {ICY_NAME}\r\n'
        f'icy-genre: {ICY_GENRE}\r\n'
        f'icy-bitrate: {BITRATE}\r\n'
        f'icy-pub: 0\r\n'
        f'\r\n'
    ).encode()


def main():
    key = load_key()
    cipher = Cipher(
        algorithms.AES(key),
        modes.CBC(IV),
        backend=default_backend(),
    )
    encryptor = cipher.encryptor()

    sock = socket.create_connection(
        (SHOUTCAST_HOST, SHOUTCAST_PORT),
        timeout=10,
    )
    sock.sendall(build_http_source_headers())

    buffer = b''
    try:
        while True:
            chunk = sys.stdin.buffer.read(4096)
            if not chunk:
                break
            buffer += chunk
            # AES-CBC needs 16-byte blocks
            aligned = len(buffer) - (len(buffer) % 16)
            if aligned > 0:
                encrypted = encryptor.update(buffer[:aligned])
                sock.sendall(encrypted)
                buffer = buffer[aligned:]

        # Final flush with PKCS7 padding
        if buffer:
            pad_len = 16 - (len(buffer) % 16)
            buffer += bytes([pad_len]) * pad_len
            sock.sendall(encryptor.update(buffer))
            sock.sendall(encryptor.finalize())
    finally:
        sock.close()


if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(f'encrypt_and_forward error: {e}', file=sys.stderr)
        sys.exit(1)
