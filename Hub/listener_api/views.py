import os
import secrets
import requests
from pathlib import Path
from django.http import StreamingHttpResponse, HttpResponse
from django.views.decorators.cache import never_cache
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, viewsets, permissions
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend
from rest_framework.pagination import PageNumberPagination
from rest_framework.filters import SearchFilter, OrderingFilter

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
        radio_id = request.data.get("radioId", "radio_123")
        time_range = request.data.get("timeRange", "last_30_days")
        categories = request.data.get("includeCategories", ["audimat", "shows", "revenue", "scheduling", "comparisons", "diagnostics"])

        try:
            from firebase_admin_config import get_firestore_db
            db = get_firestore_db()
        except Exception:
            db = None

        from insights.engine import RadioInsightsEngine
        import os
        llm = None
        if os.environ.get('OPENAI_API_KEY'):
            try:
                from insights.llm import LLMClient
                llm = LLMClient()
            except Exception:
                llm = None
        engine = RadioInsightsEngine(db=db, llm=llm)
        insights = engine.generate(radio_id, time_range)

        filtered_insights = {k: v for k, v in insights.items() if k in categories or k == "meta"}
        return Response(filtered_insights, status=status.HTTP_200_OK)


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
        }, status=status.HTTP_200_OK)


class CalculateAnnouncementPriceView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        word_count = int(request.data.get("wordCount", 20))
        duration_sec = int(request.data.get("durationSeconds", 30))
        diffusion_count = int(request.data.get("diffusionCount", 1))
        
        rate_per_word = 5.0
        rate_per_sec = 50.0
        
        base_tariff = (word_count * rate_per_word) + (duration_sec * rate_per_sec) * (1 + 0.1 * (diffusion_count - 1))
        if base_tariff < 1000.0:
            base_tariff = 1000.0
            
        transfer_fee = base_tariff * 0.04
        final_price = base_tariff + transfer_fee

        return Response({
            "base_tariff": base_tariff,
            "transfer_fee": transfer_fee,
            "final_price": final_price,
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


@csrf_exempt
@require_http_methods(["GET", "POST"])
def get_or_rotate_stream_key(request, radio_id):
    """
    Secure endpoint for studio encoders (encrypt_and_forward.py) to dynamically
    fetch their station's 16-byte AES-128 stream encryption key over HTTPS.
    
    Authentication via:
      Header: X-Station-Key: <api_key>
      OR Header: Authorization: Bearer <api_key>
    
    Optional rotation:
      POST with ?rotate=true or body {"rotate": true} rotates the AES key.
    """
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


@never_cache
def stream_radio(request, radio_id):
    """
    Proxy live audio stream from internal Shoutcast instance (127.0.0.1:8000).
    Decrypts AES-128-CBC encrypted stream from Shoutcast before sending plain MP3 to listener.
    """
    key = _get_station_aes_key(radio_id)
    if not key:
        return HttpResponse("Server key missing or misconfigured for station", status=500)

    shoutcast_host = os.environ.get("SHOUTCAST_HOST", "127.0.0.1")
    shoutcast_port = os.environ.get("SHOUTCAST_PORT", "8000")
    shoutcast_mount = os.environ.get("SHOUTCAST_MOUNT", "stream")
    shoutcast_url = f"http://{shoutcast_host}:{shoutcast_port}/{shoutcast_mount}"

    try:
        upstream = requests.get(
            shoutcast_url,
            stream=True,
            timeout=10,
        )
        if upstream.status_code != 200:
            return HttpResponse("Stream unavailable", status=503)
    except requests.RequestException:
        return HttpResponse("Stream unavailable", status=503)

    def decrypt_chunks():
        cipher = Cipher(
            algorithms.AES(key),
            modes.CBC(IV),
            backend=default_backend(),
        )
        decryptor = cipher.decryptor()
        buffer = b""
        try:
            for chunk in upstream.iter_content(chunk_size=16384):
                if not chunk:
                    continue
                buffer += chunk
                aligned = len(buffer) - (len(buffer) % 16)
                if aligned > 0:
                    plain = decryptor.update(buffer[:aligned])
                    yield plain
                    buffer = buffer[aligned:]
        finally:
            upstream.close()

    response = StreamingHttpResponse(
        decrypt_chunks(),
        content_type="audio/mpeg",
    )
    response["Cache-Control"] = "no-cache, no-store"
    response["X-Accel-Buffering"] = "no"
    response["Icy-Name"] = f"RadioHub - {radio_id}"
    response["Icy-Genre"] = "Live Radio"
    return response



