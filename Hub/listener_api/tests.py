import sys
from pathlib import Path
from django.test import TestCase, Client
from django.urls import reverse
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend

from listener_api.models import StationStreamKey
from listener_api.views import IV


from unittest.mock import patch, MagicMock
from django.core.cache import cache

class StationStreamKeyTests(TestCase):
    def setUp(self):
        cache.clear()
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

    def test_endpoint_dynamic_nonce(self):
        """Test that X-Stream-Nonce header registers active session nonce and returns it."""
        url = reverse("internal-stream-key", kwargs={"radio_id": "test_radio_1"})
        test_nonce = "11223344556677889900aabbccddeeff"
        response = self.client.get(
            url,
            HTTP_X_STATION_KEY=self.station.api_key,
            HTTP_X_STREAM_NONCE=test_nonce,
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.headers.get("X-Stream-Nonce-Hex"), test_nonce)

    def test_endpoint_rate_limiting(self):
        """Test that calling the endpoint twice within 10 seconds triggers HTTP 429."""
        url = reverse("internal-stream-key", kwargs={"radio_id": "test_radio_1"})
        # 1st request -> 200 OK
        resp1 = self.client.get(url, HTTP_X_STATION_KEY=self.station.api_key)
        self.assertEqual(resp1.status_code, 200)

        # 2nd request immediately -> 429 Too Many Requests
        resp2 = self.client.get(url, HTTP_X_STATION_KEY=self.station.api_key)
        self.assertEqual(resp2.status_code, 429)
        self.assertIn(b"Rate limit exceeded", resp2.content)

    def test_announcement_print_view(self):
        """Test the official stamped printable announcement sheet."""
        url = reverse("announcement-print", kwargs={"announcement_id": "ann_test_999"})
        response = self.client.get(url)
        self.assertEqual(response.status_code, 200)
        self.assertIn("text/html", response["Content-Type"])
        content = response.content.decode("utf-8")
        self.assertIn("ORDRE OFFICIEL DE DIFFUSION", content)
        self.assertIn("BON POUR DIFFUSION", content)
        self.assertIn("ESCROW VALIDÉ & LIBÉRÉ", content)
        self.assertIn("ann_test_999", content)

    def test_calculate_announcement_price(self):
        """Test authoritative backend price calculation."""
        url = reverse("announcement-calculate-price")
        data = {
            "radioId": "test_radio_1",
            "category": "Condolence",
            "wordCount": 50,
            "durationSeconds": 30,
            "diffusionCount": 2,
        }
        response = self.client.post(url, data, content_type="application/json")
        self.assertEqual(response.status_code, 200)
        json_resp = response.json()
        self.assertIn("baseTariff", json_resp)
        self.assertIn("transferFee", json_resp)
        self.assertIn("finalPrice", json_resp)
        # transferFee must be 4%
        expected_fee = round(json_resp["baseTariff"] * 0.04, 2)
        self.assertAlmostEqual(json_resp["transferFee"], expected_fee, places=2)
        self.assertAlmostEqual(json_resp["finalPrice"], json_resp["baseTariff"] + json_resp["transferFee"], places=2)

    def test_suggest_announcement_text(self):
        """Test announcement text suggestion."""
        url = reverse("announcement-suggest-text")
        data = {
            "category": "Birthday",
            "rawText": "Happy 30th birthday to Paul from his family in Douala.",
        }
        response = self.client.post(url, data, content_type="application/json")
        self.assertEqual(response.status_code, 200)
        json_resp = response.json()
        self.assertIn("suggestedText", json_resp)
        self.assertIn("wordCount", json_resp)
        self.assertIn("estimatedDurationSeconds", json_resp)

    @patch("listener_api.views.process_lapsed_subscriptions_escrow")
    def test_lapsed_escrow_endpoint(self, mock_process):
        """Test internal lapsed escrow refund trigger."""
        mock_process.return_value = {
            "status": "success",
            "refunded_announcements": 2,
            "radios_affected": 1,
            "processed_at": "2026-09-29T22:00:00",
        }
        url = reverse("internal-process-lapsed-escrow")
        response = self.client.post(url)
        self.assertEqual(response.status_code, 200)
        json_resp = response.json()
        self.assertEqual(json_resp["status"], "success")
        self.assertEqual(json_resp["refunded_announcements"], 2)


from unittest.mock import patch, MagicMock

class EncryptAndForwardIntegrationTest(TestCase):
    def setUp(self):
        cache.clear()
        self.station = StationStreamKey.generate_key_pair(
            radio_id="station_live_test",
            radio_name="Live Test Radio",
        )

    def test_encrypt_and_forward_loads_key_from_django(self):
        sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "scripts" / "radio"))
        import encrypt_and_forward

        mock_resp = MagicMock()
        mock_resp.status = 200
        mock_resp.read.return_value = self.station.get_aes_bytes()
        mock_resp.__enter__.return_value = mock_resp

        with patch("urllib.request.build_opener") as mock_opener_cls:
            mock_opener = MagicMock()
            mock_opener.open.return_value = mock_resp
            mock_opener_cls.return_value = mock_opener

            encrypt_and_forward.DJANGO_API_URL = "http://localhost:8002"
            encrypt_and_forward.RADIO_ID = self.station.radio_id
            encrypt_and_forward.STATION_API_KEY = self.station.api_key

            fetched_key = encrypt_and_forward.load_key()
            self.assertEqual(fetched_key, self.station.get_aes_bytes())



