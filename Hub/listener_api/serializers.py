from rest_framework import serializers
from listener_api.models import Category, Show, Episode, LiveStreamConfig, Announcement


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ["id", "name", "slug", "icon"]


class ShowSerializer(serializers.ModelSerializer):
    category = CategorySerializer(read_only=True)
    category_id = serializers.PrimaryKeyRelatedField(
        queryset=Category.objects.all(), source="category", write_only=True, required=False
    )

    class Meta:
        model = Show
        fields = [
            "id",
            "title",
            "description",
            "cover_image",
            "host_name",
            "schedule_time",
            "category",
            "category_id",
            "is_active",
        ]


class EpisodeSerializer(serializers.ModelSerializer):
    show_title = serializers.CharField(source="show.title", read_only=True)

    class Meta:
        model = Episode
        fields = [
            "id",
            "show",
            "show_title",
            "title",
            "description",
            "audio_file",
            "duration",
            "published_at",
            "play_count",
        ]


class LiveStreamConfigSerializer(serializers.ModelSerializer):
    class Meta:
        model = LiveStreamConfig
        fields = [
            "id",
            "stream_url",
            "is_live",
            "current_title",
            "current_host",
            "banner_message",
            "updated_at",
        ]


class AnnouncementSerializer(serializers.ModelSerializer):
    class Meta:
        model = Announcement
        fields = [
            "id",
            "title",
            "message",
            "type",
            "is_active",
            "start_time",
            "end_time",
        ]
