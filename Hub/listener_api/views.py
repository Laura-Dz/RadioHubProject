import os
import secrets
import requests
from datetime import datetime, timedelta
from pathlib import Path
from django.http import StreamingHttpResponse, HttpResponse, JsonResponse
from django.views.decorators.cache import never_cache
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from django.utils import timezone
from django.core.cache import cache
from django.conf import settings
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, viewsets, permissions
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend
from rest_framework.pagination import PageNumberPagination
from rest_framework.filters import SearchFilter, OrderingFilter

try:
    from firebase_admin_config import get_firestore_db
except Exception:
    get_firestore_db = None

from listener_api.models import LiveStreamConfig, Episode, Show, Announcement, StationStreamKey
from listener_api.serializers import (
    LiveStreamConfigSerializer,
    EpisodeSerializer,
    ShowSerializer,
    AnnouncementSerializer,
)


class StandardResultsSetPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = "page_size"
    max_page_size = 100


class ActiveLiveStreamView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        try:
            stream = LiveStreamConfig.objects.filter(is_live=True).latest("updated_at")
        except LiveStreamConfig.DoesNotExist:
            return Response(
                {"detail": "No active live stream found."},
                status=status.HTTP_404_NOT_FOUND,
            )

        now = timezone.now()
        active_announcements = Announcement.objects.filter(
            is_active=True,
            start_time__lte=now,
            end_time__gte=now,
        ).order_by("-start_time")[:5]

        stream_data = LiveStreamConfigSerializer(stream).data
        announcement_data = AnnouncementSerializer(active_announcements, many=True).data

        return Response(
            {
                "live_stream": stream_data,
                "announcements": announcement_data,
            },
            status=status.HTTP_200_OK,
        )


class EpisodeListViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Episode.objects.select_related("show").all()
    serializer_class = EpisodeSerializer
    permission_classes = [permissions.AllowAny]
    pagination_class = StandardResultsSetPagination
    filter_backends = [SearchFilter, OrderingFilter]
    search_fields = ["title", "description", "show__title", "show__host_name"]
    ordering_fields = ["published_at", "play_count", "duration"]
    ordering = ["-published_at"]

    def get_queryset(self):
        queryset = super().get_queryset()
        show_id = self.request.query_params.get("show")
        if show_id:
            queryset = queryset.filter(show_id=show_id)
        return queryset


class ShowScheduleViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Show.objects.filter(is_active=True).select_related("category")
    serializer_class = ShowSerializer
    permission_classes = [permissions.AllowAny]
    pagination_class = StandardResultsSetPagination
    filter_backends = [SearchFilter, OrderingFilter]
    search_fields = ["title", "description", "host_name"]
    ordering_fields = ["schedule_time"]
    ordering = ["schedule_time"]

    def get_queryset(self):
        queryset = super().get_queryset()
        now = timezone.now()
        filter_type = self.request.query_params.get("filter")

        if filter_type == "upcoming":
            return queryset.filter(schedule_time__gt=now)
        elif filter_type == "active":
            return queryset.filter(schedule_time__lte=now)
        return queryset


class ActiveAnnouncementsView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        now = timezone.now()
        announcements = Announcement.objects.filter(
            is_active=True,
            start_time__lte=now,
            end_time__gte=now,
        ).order_by("-start_time")
        serializer = AnnouncementSerializer(announcements, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


class RadioInsightsView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        from insights.views import RadioInsightsView as InsightsBaseView
        return InsightsBaseView().post(request)


class SuggestAnnouncementTextView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        original_text = request.data.get("text", "")
        category = request.data.get("category", "General")
        
        # Simple AI improvement simulation
        improved_text = f"[{category.upper()}] {original_text} — Diffusé avec amour sur votre radio préférée!"
        if "birthday" in category.lower() or "anniversaire" in original_text.lower():
            improved_text = f"🎉 Joyeux Anniversaire! {original_text} Que cette nouvelle année vous apporte joie, santé et succès!"
        elif "condolence" in category.lower() or "décès" in original_text.lower():
            improved_text = f"🕊️ Nos sincères condoléances. {original_text} Que son âme repose en paix éternelle."

        word_count = len(improved_text.split())
        est_duration = max(15, word_count * 2)

        return Response({
            "original_text": original_text,
            "improved_text": improved_text,
            "word_count": word_count,
            "estimated_duration_seconds": est_duration,
            "originalText": original_text,
            "suggestedText": improved_text,
            "wordCount": word_count,
            "estimatedDurationSeconds": est_duration,
        }, status=status.HTTP_200_OK)


class CalculateAnnouncementPriceView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        word_count = int(request.data.get("wordCount", request.data.get("word_count", 20)))
        duration_sec = int(request.data.get("durationSeconds", request.data.get("duration_seconds", 30)))
        diffusion_count = int(request.data.get("diffusionCount", request.data.get("diffusion_count", 1)))
        
        rate_per_word = 5.0
        rate_per_sec = 50.0
        
        base_tariff = (word_count * rate_per_word) + (duration_sec * rate_per_sec) * (1 + 0.1 * (diffusion_count - 1))
        if base_tariff < 1000.0:
            base_tariff = 1000.0
            
        transfer_fee = round(base_tariff * 0.04, 2)
        final_price = round(base_tariff + transfer_fee, 2)

        return Response({
            "base_tariff": base_tariff,
            "transfer_fee": transfer_fee,
            "final_price": final_price,
            "baseTariff": base_tariff,
            "transferFee": transfer_fee,
            "finalPrice": final_price,
            "currency": "XAF",
            "fee_percentage": 4.0,
        }, status=status.HTTP_200_OK)


KEY_FILE_DEFAULT = Path("/opt/radio/current.key")
IV = b"\x00" * 16


def _load_aes_key() -> bytes | None:
    env_path = os.environ.get("AES_KEY_FILE")
    candidates = [
        Path(env_path) if env_path else None,
        KEY_FILE_DEFAULT,
        Path(__file__).resolve().parent.parent / "current.key",
        Path(__file__).resolve().parent.parent.parent / "scripts" / "radio" / "current.key",
    ]
    for p in candidates:
        if p and p.exists():
            try:
                data = p.read_bytes()
                if len(data) == 16:
                    return data
            except Exception:
                pass
    return None


def _get_station_aes_key(radio_id: str) -> bytes | None:
    """
    Look up station-specific AES key from StationStreamKey model.
    Falls back to local key file / env if station record does not exist.
    """
    try:
        station = StationStreamKey.objects.filter(radio_id=radio_id, is_active=True).first()
        if station:
            return station.get_aes_bytes()
    except Exception:
        pass
    return _load_aes_key()


def _check_ip_allowed(request) -> bool:
    """Verifies client IP against ALLOWED_STUDIO_IPS if configured."""
    allowed_ips_setting = getattr(settings, "ALLOWED_STUDIO_IPS", None) or os.environ.get("ALLOWED_STUDIO_IPS", "")
    if not allowed_ips_setting or allowed_ips_setting.strip() == "*":
        return True
    allowed_ips = [ip.strip() for ip in allowed_ips_setting.split(",") if ip.strip()]
    allowed_ips.extend(["127.0.0.1", "::1", "localhost", "testserver"])
    x_forwarded_for = request.META.get("HTTP_X_FORWARDED_FOR")
    client_ip = x_forwarded_for.split(",")[0].strip() if x_forwarded_for else request.META.get("REMOTE_ADDR")
    return client_ip in allowed_ips


@csrf_exempt
@require_http_methods(["GET", "POST"])
def get_or_rotate_stream_key(request, radio_id):
    """
    Secure endpoint for studio encoders (encrypt_and_forward.py) to dynamically
    fetch their station's 16-byte AES-128 stream encryption key over HTTPS.
    
    Hardened with:
      - Rate limiting: max 1 request per 10 seconds per station
      - IP allowlisting: verifies studio encoder IP
      - Authentication via header: X-Station-Key or Authorization: Bearer
    """
    # 1. IP Allowlist Verification
    if not _check_ip_allowed(request):
        return HttpResponse("Forbidden: Studio IP not authorized", status=403)

    # 2. Rate Limiting (1 request per 10 seconds per station)
    rate_limit_key = f"ratelimit_stream_key_{radio_id}"
    if cache.get(rate_limit_key):
        return HttpResponse("Rate limit exceeded: max 1 request per 10 seconds per station", status=429)
    cache.set(rate_limit_key, True, timeout=10)

    # 3. Authentication
    auth_key = request.headers.get("X-Station-Key")
    if not auth_key:
        auth_header = request.headers.get("Authorization", "")
        if auth_header.startswith("Bearer "):
            auth_key = auth_header[7:].strip()

    if not auth_key:
        return HttpResponse("Missing station authentication key (header 'X-Station-Key' required)", status=401)

    try:
        station = StationStreamKey.objects.get(radio_id=radio_id, is_active=True)
    except StationStreamKey.DoesNotExist:
        return HttpResponse("Station not found or inactive", status=404)

    if not secrets.compare_digest(station.api_key, auth_key):
        return HttpResponse("Invalid station credentials", status=403)

    rotate = request.GET.get("rotate", "").lower() in ("true", "1")
    if request.method == "POST" and not rotate:
        try:
            import json
            body = json.loads(request.body) if request.body else {}
            if body.get("rotate") is True:
                rotate = True
        except Exception:
            pass

    if rotate:
        station.rotate_aes_key()

    aes_bytes = station.get_aes_bytes()
    response = HttpResponse(aes_bytes, content_type="application/octet-stream")
    response["Cache-Control"] = "no-store, no-cache, must-revalidate, private"
    response["X-AES-Key-Hex"] = station.aes_key_hex
    response["X-Radio-Id"] = station.radio_id
    return response


def _get_mp3_frame_size(b: bytes, offset: int = 0) -> int | None:
    if len(b) - offset < 4:
        return None
    if b[offset] != 0xFF or (b[offset + 1] & 0xE0) != 0xE0:
        return None
    version_bits = (b[offset + 1] >> 3) & 0x03
    layer_bits = (b[offset + 1] >> 1) & 0x03
    bitrate_idx = (b[offset + 2] >> 4) & 0x0F
    sample_rate_idx = (b[offset + 2] >> 2) & 0x03
    padding = (b[offset + 2] >> 1) & 0x01

    if layer_bits != 1:
        return None

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


def _xor_payload(payload: bytes, keystream: bytes) -> bytes:
    L = len(payload)
    if L == 0:
        return b""
    return (int.from_bytes(payload, "big") ^ int.from_bytes(keystream[:L], "big")).to_bytes(L, "big")


@never_cache
def stream_radio(request, radio_id):
    """
    Proxy live audio stream from internal Shoutcast instance (127.0.0.1:8000).
    Streams pure live MP3 to the listener. If encryption is enabled in settings,
    it decrypts; otherwise, it streams the raw audio chunks directly from the mixer.
    """
    shoutcast_host = os.environ.get("SHOUTCAST_HOST", "127.0.0.1")
    shoutcast_port = os.environ.get("SHOUTCAST_PORT", "8000")
    shoutcast_mount = os.environ.get("SHOUTCAST_MOUNT", "stream/1/")
    shoutcast_url = f"http://{shoutcast_host}:{shoutcast_port}/{shoutcast_mount}"

    try:
        upstream = requests.get(
            shoutcast_url,
            stream=True,
            timeout=10,
        )
        if upstream.status_code != 200:
            upstream = requests.get(
                f"http://{shoutcast_host}:{shoutcast_port}/;",
                stream=True,
                timeout=10,
            )
            if upstream.status_code != 200:
                return HttpResponse("Stream unavailable", status=503)
    except requests.RequestException:
        return HttpResponse("Stream unavailable", status=503)

    key = _get_station_aes_key(radio_id)
    encryption_enabled = os.environ.get("ENABLE_STREAM_ENCRYPTION", "true").lower() in ("true", "1", "yes")

    def audio_chunks():
        try:
            if encryption_enabled and key:
                cipher = Cipher(
                    algorithms.AES(key),
                    modes.CTR(IV),
                    backend=default_backend(),
                )
                keystream = cipher.encryptor().update(b"\x00" * 4096)
                buffer = bytearray()
                for chunk in upstream.iter_content(chunk_size=8192):
                    if not chunk:
                        continue
                    buffer.extend(chunk)

                    out = bytearray()
                    while True:
                        if len(buffer) < 4:
                            break

                        if buffer[0] != 0xFF or (buffer[1] & 0xE0) != 0xE0:
                            idx = -1
                            for i in range(1, len(buffer) - 1):
                                if buffer[i] == 0xFF and (buffer[i + 1] & 0xE0) == 0xE0:
                                    idx = i
                                    break
                            if idx != -1:
                                out.extend(buffer[:idx])
                                buffer = buffer[idx:]
                            else:
                                if buffer[-1] == 0xFF:
                                    out.extend(buffer[:-1])
                                    buffer = buffer[-1:]
                                else:
                                    out.extend(buffer)
                                    buffer.clear()
                                break

                        frame_size = _get_mp3_frame_size(buffer, 0)
                        if frame_size is None or len(buffer) < frame_size:
                            break

                        hdr = bytes(buffer[:4])
                        payload = bytes(buffer[4:frame_size])
                        del buffer[:frame_size]

                        dec_payload = _xor_payload(payload, keystream)
                        out.extend(hdr + dec_payload)

                    if out:
                        yield bytes(out)
            else:
                for chunk in upstream.iter_content(chunk_size=8192):
                    if chunk:
                        yield chunk
        finally:
            upstream.close()

    response = StreamingHttpResponse(
        audio_chunks(),
        content_type="audio/mpeg",
    )
    response["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response["X-Accel-Buffering"] = "no"
    response["Icy-Name"] = f"RadioHub - {radio_id}"
    response["Icy-Genre"] = "Live Radio"
    return response


# ==============================================================================
# OFFICIAL STAMPED ANNOUNCEMENT PRINT VIEW (CONTINGENCY / BACKUP PRINTING)
# ==============================================================================

@never_cache
def announcement_print_view(request, announcement_id: str):
    """
    Renders an official stamped broadcast order sheet formatted for A4 printing.
    Includes station header, verification QR code, official rubber seal, scheduled slots,
    and broadcast teleprompter copy.
    """
    ann_data = {}
    radio_data = {}
    
    if get_firestore_db:
        try:
            db = get_firestore_db()
            if db:
                doc = db.collection("announcements").doc(announcement_id).get()
                if doc.exists:
                    ann_data = doc.to_dict()
                    radio_id = ann_data.get("radioId")
                    if radio_id:
                        r_doc = db.collection("radios").doc(radio_id).get()
                        if r_doc.exists:
                            radio_data = r_doc.to_dict()
        except Exception:
            pass

    # Extract fields with safe fallbacks
    radio_name = radio_data.get("name") or ann_data.get("radioName") or "RadioHub Station"
    radio_freq = radio_data.get("frequency") or "FM Stereo"
    category = ann_data.get("category") or "Communiqué Général"
    listener_name = ann_data.get("listenerName") or "Auditeur RadioHub"
    listener_email = ann_data.get("listenerEmail") or "Non spécifié"
    final_text = ann_data.get("finalText") or ann_data.get("originalMessage") or "Texte de l'annonce en cours de traitement."
    word_count = ann_data.get("wordCount") or len(final_text.split())
    duration_sec = ann_data.get("estimatedDurationSeconds") or max(15, word_count // 2)
    diffusion_count = ann_data.get("diffusionCount") or 1
    diffusion_period = ann_data.get("diffusionPeriodDays") or 7
    final_price = ann_data.get("finalPrice") or ann_data.get("baseTariff") or 0.0
    currency = ann_data.get("currency") or "XAF"
    payment_method = ann_data.get("paymentMethod") or "Mobile Money (MoMo)"
    status_str = (ann_data.get("status") or "VALIDATED").upper()
    validated_by = ann_data.get("validatedBy") or "Direction des Programmes"
    
    val_at = ann_data.get("validatedAt")
    if hasattr(val_at, "strftime"):
        validated_at_str = val_at.strftime("%d/%m/%Y à %H:%M")
    else:
        validated_at_str = datetime.now().strftime("%d/%m/%Y à %H:%M")

    qr_url = f"https://api.qrserver.com/v1/create-qr-code/?size=140x140&margin=4&data=https://radiohub.cm/verify/announcement/{announcement_id}"

    html_content = f"""<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Ordre de Diffusion - {announcement_id}</title>
    <style>
        @page {{
            size: A4;
            margin: 15mm;
        }}
        * {{
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }}
        body {{
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            color: #1a1a2e;
            background: #f4f6fa;
            padding: 24px;
        }}
        .no-print {{
            max-width: 820px;
            margin: 0 auto 16px auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
            background: #ffffff;
            padding: 14px 20px;
            border-radius: 10px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        }}
        .btn {{
            display: inline-flex;
            align-items: center;
            gap: 8px;
            background: #564ECC;
            color: #ffffff;
            border: none;
            padding: 10px 18px;
            border-radius: 6px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            text-decoration: none;
        }}
        .btn-secondary {{
            background: #e5e7eb;
            color: #374151;
        }}
        .sheet {{
            max-width: 820px;
            margin: 0 auto;
            background: #ffffff;
            border: 2px solid #1a1a2e;
            padding: 32px;
            border-radius: 4px;
            box-shadow: 0 4px 16px rgba(0,0,0,0.06);
            position: relative;
        }}
        .header-republic {{
            display: flex;
            justify-content: space-between;
            font-size: 11px;
            text-transform: uppercase;
            font-weight: bold;
            letter-spacing: 0.5px;
            border-bottom: 1px solid #d1d5db;
            padding-bottom: 8px;
            margin-bottom: 16px;
            color: #4b5563;
        }}
        .station-header {{
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 16px;
            border-bottom: 2px solid #564ECC;
        }}
        .station-title {{
            font-size: 24px;
            font-weight: 900;
            color: #564ECC;
        }}
        .station-meta {{
            font-size: 13px;
            color: #6b7280;
            margin-top: 4px;
        }}
        .doc-title-badge {{
            text-align: center;
            background: #1a1a2e;
            color: #ffffff;
            padding: 8px 16px;
            font-size: 15px;
            font-weight: 800;
            letter-spacing: 1px;
            border-radius: 4px;
            margin-bottom: 24px;
        }}
        .grid-info {{
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 20px;
            margin-bottom: 24px;
        }}
        .table-info {{
            width: 100%;
            border-collapse: collapse;
            font-size: 12.5px;
        }}
        .table-info td {{
            padding: 6px 10px;
            border-bottom: 1px solid #f3f4f6;
        }}
        .table-info td.label {{
            font-weight: 700;
            color: #4b5563;
            width: 35%;
        }}
        .table-info td.val {{
            font-weight: 600;
            color: #111827;
        }}
        .stamp-box {{
            border: 2px dashed #dc2626;
            border-radius: 8px;
            padding: 12px;
            text-align: center;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            position: relative;
            background: #fef2f2;
        }}
        .stamp-seal {{
            color: #b91c1c;
            font-size: 14px;
            font-weight: 900;
            text-transform: uppercase;
            letter-spacing: 1px;
            border: 3px solid #b91c1c;
            padding: 6px 14px;
            border-radius: 6px;
            transform: rotate(-4deg);
            margin-bottom: 8px;
        }}
        .script-container {{
            background: #f8fafc;
            border-left: 5px solid #564ECC;
            padding: 20px;
            border-radius: 4px;
            margin-bottom: 28px;
        }}
        .script-label {{
            font-size: 12px;
            font-weight: 800;
            text-transform: uppercase;
            color: #564ECC;
            letter-spacing: 1px;
            margin-bottom: 8px;
        }}
        .script-body {{
            font-size: 16px;
            line-height: 1.6;
            color: #1e293b;
            font-weight: 500;
            white-space: pre-wrap;
        }}
        .footer-signatures {{
            display: flex;
            justify-content: space-between;
            align-items: flex-end;
            margin-top: 36px;
            padding-top: 16px;
            border-top: 1px solid #e5e7eb;
        }}
        .sig-block {{
            text-align: center;
            width: 220px;
        }}
        .sig-line {{
            height: 48px;
            border-bottom: 1.5px solid #1a1a2e;
            margin-bottom: 6px;
        }}
        .sig-label {{
            font-size: 11px;
            font-weight: 700;
            color: #6b7280;
            text-transform: uppercase;
        }}
        .qr-section {{
            display: flex;
            align-items: center;
            gap: 12px;
        }}
        .qr-section img {{
            width: 90px;
            height: 90px;
            border: 1px solid #d1d5db;
            border-radius: 4px;
        }}
        .qr-meta {{
            font-size: 10.5px;
            color: #6b7280;
            line-height: 1.35;
        }}

        @media print {{
            body {{
                background: #ffffff;
                padding: 0;
            }}
            .no-print {{
                display: none !important;
            }}
            .sheet {{
                border: none;
                box-shadow: none;
                padding: 0;
                width: 100%;
                max-width: 100%;
            }}
        }}
    </style>
</head>
<body>
    <div class="no-print">
        <div>
            <strong>Fiche Officielle de Diffusion d'Annonce</strong>
            <span style="color:#6b7280; font-size:12px; margin-left:8px;">(Failsafe & Archival Print)</span>
        </div>
        <div style="display:flex; gap:10px;">
            <button class="btn" onclick="window.print()">🖨️ Imprimer la fiche (Print)</button>
            <button class="btn btn-secondary" onclick="window.close()">Fermer</button>
        </div>
    </div>

    <div class="sheet">
        <div class="header-republic">
            <div>RÉPUBLIQUE DU CAMEROUN<br><span style="font-weight:normal; font-size:9.5px;">Paix – Travail – Patrie</span></div>
            <div style="text-align:right;">REPUBLIC OF CAMEROON<br><span style="font-weight:normal; font-size:9.5px;">Peace – Work – Fatherland</span></div>
        </div>

        <div class="station-header">
            <div>
                <div class="station-title">{radio_name}</div>
                <div class="station-meta">Fréquence : {radio_freq} · Suite de Diffusion RadioHub</div>
            </div>
            <div style="text-align:right;">
                <div style="font-size:12px; font-weight:bold; color:#4b5563;">RÉFÉRENCE ANNONCE</div>
                <div style="font-size:13px; font-weight:800; color:#1a1a2e; font-family:monospace;">{announcement_id}</div>
            </div>
        </div>

        <div class="doc-title-badge">
            ORDRE OFFICIEL DE DIFFUSION EN ONDE (BROADCAST ORDER)
        </div>

        <div class="grid-info">
            <table class="table-info">
                <tr><td class="label">Catégorie :</td><td class="val">{category}</td></tr>
                <tr><td class="label">Demandeur :</td><td class="val">{listener_name} ({listener_email})</td></tr>
                <tr><td class="label">Diffusions :</td><td class="val">{diffusion_count} passage(s) sur {diffusion_period} jours</td></tr>
                <tr><td class="label">Durée estimée :</td><td class="val">{duration_sec} sec · {word_count} mots</td></tr>
                <tr><td class="label">Montant Réglé :</td><td class="val" style="color:#059669; font-weight:bold;">{final_price:,.0f} {currency} ({payment_method})</td></tr>
                <tr><td class="label">Validation :</td><td class="val">{validated_at_str} par {validated_by}</td></tr>
            </table>

            <div class="stamp-box">
                <div class="stamp-seal">BON POUR DIFFUSION</div>
                <div style="font-size:11px; font-weight:bold; color:#991b1b;">ESCROW VALIDÉ & LIBÉRÉ</div>
                <div style="font-size:10px; color:#6b7280; margin-top:4px;">Visa Direction des Programmes</div>
            </div>
        </div>

        <div class="script-container">
            <div class="script-label">TEXTE À LIRE À L'ANTENNE (SCRIPT PROMPTER) :</div>
            <div class="script-body">{final_text}</div>
        </div>

        <div class="footer-signatures">
            <div class="qr-section">
                <img src="{qr_url}" alt="Verification QR Code">
                <div class="qr-meta">
                    <strong>Vérification Numérique</strong><br>
                    Scannez pour valider le statut en direct sur RadioHub.<br>
                    ID: {announcement_id[:16]}...
                </div>
            </div>

            <div class="sig-block">
                <div class="sig-line"></div>
                <div class="sig-label">Signature du Présentateur / Opérateur</div>
            </div>

            <div class="sig-block">
                <div class="sig-line"></div>
                <div class="sig-label">Visa & Cachet Station</div>
            </div>
        </div>
    </div>
</body>
</html>"""
    return HttpResponse(html_content, content_type="text/html; charset=utf-8")


# ==============================================================================
# 72-HOUR LAPSED SUBSCRIPTION ESCROW REFUND ENGINE
# ==============================================================================

def process_lapsed_subscriptions_escrow() -> dict:
    """
    Scans Firestore for radio stations whose subscription expired past the 72-hour grace period.
    Automatically refunds pending 'inEscrow' announcements back to listeners.
    """
    if not get_firestore_db:
        return {"status": "error", "message": "Firestore DB client not available"}

    db = get_firestore_db()
    if not db:
        return {"status": "error", "message": "Firestore connection could not be established"}

    now = datetime.utcnow()
    grace_cutoff = now - timedelta(hours=72)
    refunded_count = 0
    radios_affected = []

    try:
        radios_stream = db.collection("radios").stream(timeout=5)
        for r_doc in radios_stream:
            r_data = r_doc.to_dict()
            radio_id = r_doc.id
            sub_status = (r_data.get("subscriptionStatus") or "active").lower()
            expires_at = r_data.get("subscriptionExpiresAt")

            is_lapsed = False
            if sub_status in ("suspended", "expired"):
                is_lapsed = True
            elif expires_at:
                exp_dt = None
                if hasattr(expires_at, "to_datetime"):
                    exp_dt = expires_at.to_datetime().replace(tzinfo=None)
                elif isinstance(expires_at, datetime):
                    exp_dt = expires_at.replace(tzinfo=None)
                if exp_dt and exp_dt < grace_cutoff:
                    is_lapsed = True

            if not is_lapsed:
                continue

            ann_query = db.collection("announcements").where("radioId", "==", radio_id).where("status", "==", "inEscrow")
            announcements = list(ann_query.stream(timeout=5))

            if announcements:
                radios_affected.append(radio_id)
                for a_doc in announcements:
                    a_data = a_doc.to_dict()
                    a_id = a_doc.id
                    price = float(a_data.get("finalPrice", 0.0))
                    currency = a_data.get("currency", "XAF")
                    listener_id = a_data.get("listenerId", "")

                    # 1. Transition status to expired_refunded
                    a_doc.reference.update({
                        "status": "expired_refunded",
                        "refundedAt": now,
                        "refundReason": "Station subscription expired past 72-hour grace period",
                    })

                    # 2. Add refund ledger record in transactions
                    db.collection("transactions").add({
                        "radioId": radio_id,
                        "announcementId": a_id,
                        "listenerId": listener_id,
                        "type": "announcement_refund",
                        "amount": price,
                        "currency": currency,
                        "status": "refunded",
                        "reason": "Station subscription expired past 72-hour grace period",
                        "createdAt": now,
                    })

                    # 3. Notify listener
                    if listener_id:
                        db.collection("notifications").add({
                            "userId": listener_id,
                            "type": "announcement_refunded",
                            "title": "⚠️ Remboursement d'annonce (Station expirée)",
                            "body": f"Votre annonce n'a pu être diffusée car l'abonnement de la station a expiré. Le montant de {price:,.0f} {currency} a été remboursé.",
                            "data": {
                                "announcementId": a_id,
                                "radioId": radio_id,
                                "refundedAt": now.isoformat(),
                            },
                            "isRead": False,
                            "createdAt": now,
                        })

                    refunded_count += 1

        return {
            "status": "success",
            "refunded_announcements": refunded_count,
            "radios_affected": len(radios_affected),
            "processed_at": now.isoformat(),
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}


@csrf_exempt
@require_http_methods(["POST", "GET"])
def process_lapsed_escrow_view(request):
    """
    Internal API endpoint for automated cron / maintenance workers
    to trigger the 72-hour grace period lapsed escrow refund engine.
    """
    cron_key = os.environ.get("CRON_SECRET_KEY")
    req_key = request.headers.get("X-Cron-Key") or request.GET.get("key")
    if cron_key and req_key != cron_key:
        return JsonResponse({"error": "Unauthorized"}, status=401)

    result = process_lapsed_subscriptions_escrow()
    return JsonResponse(result)



