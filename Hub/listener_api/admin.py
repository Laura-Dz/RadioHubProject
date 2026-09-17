from django.contrib import admin
from listener_api.models import Category, Show, Episode, LiveStreamConfig, Announcement, StationStreamKey


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ("name", "slug")
    search_fields = ("name", "slug")
    prepopulated_fields = {"slug": ("name",)}


@admin.register(Show)
class ShowAdmin(admin.ModelAdmin):
    list_display = ("title", "host_name", "schedule_time", "is_active", "category")
    list_filter = ("is_active", "category", "schedule_time")
    search_fields = ("title", "host_name", "description")
    autocomplete_fields = ("category",)


@admin.register(Episode)
class EpisodeAdmin(admin.ModelAdmin):
    list_display = ("title", "show", "published_at", "play_count", "duration")
    list_filter = ("published_at", "show")
    search_fields = ("title", "description", "show__title")
    autocomplete_fields = ("show",)


@admin.register(LiveStreamConfig)
class LiveStreamConfigAdmin(admin.ModelAdmin):
    list_display = ("is_live", "current_title", "current_host", "updated_at")
    list_filter = ("is_live",)


@admin.register(Announcement)
class AnnouncementAdmin(admin.ModelAdmin):
    list_display = ("title", "type", "is_active", "start_time", "end_time")
    list_filter = ("type", "is_active", "start_time", "end_time")
    search_fields = ("title", "message")


@admin.register(StationStreamKey)
class StationStreamKeyAdmin(admin.ModelAdmin):
    list_display = ("radio_id", "radio_name", "is_active", "updated_at")
    list_filter = ("is_active",)
    search_fields = ("radio_id", "radio_name", "api_key")
    readonly_fields = ("created_at", "updated_at")

