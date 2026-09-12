from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, viewsets, permissions
from rest_framework.pagination import PageNumberPagination
from rest_framework.filters import SearchFilter, OrderingFilter

from listener_api.models import LiveStreamConfig, Episode, Show, Announcement
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

