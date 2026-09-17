from pathlib import Path
from django.test import TestCase, Client
from django.urls import reverse
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend

from listener_api.models import StationStreamKey
from listener_api.views import IV


class StationStreamKeyTests(TestCase):
    def setUp(self):
        self.client = Client()
        self.station = StationStreamKey.generate_key_pair(
            radio_id="test_radio_1",
            radio_name="Test Radio FM",
        )

    def test_model_properties_and_generation(self):
        self.assertEqual(self.station.radio_id, "test_radio_1")
        self.assertTrue(self.station.is_active)
        self.assertEqual(len(self.station.api_key), 43)  # urlsafe 32 bytes ~43 chars
        self.assertEqual(len(self.station.aes_key_hex), 32)
        aes_bytes = self.station.get_aes_bytes()
        self.assertEqual(len(aes_bytes), 16)

    def test_endpoint_missing_auth(self):
        url = reverse("internal-stream-key", kwargs={"radio_id": "test_radio_1"})
        response = self.client.post(url)
        self.assertEqual(response.status_code, 401)

    def test_endpoint_wrong_key(self):
        url = reverse("internal-stream-key", kwargs={"radio_id": "test_radio_1"})
        response = self.client.post(url, HTTP_X_STATION_KEY="wrong_secret_key")
        self.assertEqual(response.status_code, 403)

    def test_endpoint_unknown_station(self):
        url = reverse("internal-stream-key", kwargs={"radio_id": "unknown_radio"})
        response = self.client.post(url, HTTP_X_STATION_KEY=self.station.api_key)
        self.assertEqual(response.status_code, 404)

    def test_endpoint_success_x_station_key(self):
        url = reverse("internal-stream-key", kwargs={"radio_id": "test_radio_1"})
        response = self.client.post(url, HTTP_X_STATION_KEY=self.station.api_key)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response["Content-Type"], "application/octet-stream")
        self.assertEqual(len(response.content), 16)
        self.assertEqual(response.content, self.station.get_aes_bytes())
        self.assertEqual(response["X-AES-Key-Hex"], self.station.aes_key_hex)

    def test_endpoint_success_bearer_auth(self):
        url = reverse("internal-stream-key", kwargs={"radio_id": "test_radio_1"})
        response = self.client.get(
            url,
            HTTP_AUTHORIZATION=f"Bearer {self.station.api_key}",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.content, self.station.get_aes_bytes())

    def test_endpoint_key_rotation(self):
        old_hex = self.station.aes_key_hex
        url = reverse("internal-stream-key", kwargs={"radio_id": "test_radio_1"}) + "?rotate=true"
        response = self.client.post(url, HTTP_X_STATION_KEY=self.station.api_key)
        self.assertEqual(response.status_code, 200)
        new_key = response.content
        self.assertNotEqual(new_key, bytes.fromhex(old_hex))

        # Check that database model is updated
        self.station.refresh_from_db()
        self.assertEqual(self.station.get_aes_bytes(), new_key)

    def test_crypto_stream_roundtrip(self):
        """Simulate encrypt_and_forward.py encrypting and stream_radio decrypting"""
        key = self.station.get_aes_bytes()

        # Sender encryption (simulate encrypt_and_forward.py)
        raw_audio_stream = b"ID3v2\x00\x00\x00\x00MP3_DUMMY_AUDIO_DATA_FOR_TESTING_1234567890" * 20
        pad_len = 16 - (len(raw_audio_stream) % 16)
        padded_raw = raw_audio_stream + (bytes([pad_len]) * pad_len)

        cipher_enc = Cipher(algorithms.AES(key), modes.CBC(IV), backend=default_backend())
        enc = cipher_enc.encryptor()
        ciphertext = enc.update(padded_raw) + enc.finalize()

        # Receiver decryption (simulate stream_radio view)
        cipher_dec = Cipher(algorithms.AES(key), modes.CBC(IV), backend=default_backend())
        dec = cipher_dec.decryptor()
        decrypted = dec.update(ciphertext) + dec.finalize()

        self.assertEqual(decrypted[:len(raw_audio_stream)], raw_audio_stream)


from django.test import LiveServerTestCase
import os
import sys

class EncryptAndForwardIntegrationTest(LiveServerTestCase):
    def setUp(self):
        self.station = StationStreamKey.generate_key_pair(
            radio_id="station_live_test",
            radio_name="Live Test Radio",
        )

    def test_encrypt_and_forward_loads_key_from_django(self):
        sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "scripts" / "radio"))
        import encrypt_and_forward

        # Point encrypt_and_forward to this test server
        encrypt_and_forward.DJANGO_API_URL = self.live_server_url
        encrypt_and_forward.RADIO_ID = self.station.radio_id
        encrypt_and_forward.STATION_API_KEY = self.station.api_key

        fetched_key = encrypt_and_forward.load_key()
        self.assertEqual(fetched_key, self.station.get_aes_bytes())

