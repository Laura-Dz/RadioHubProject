from django.db import models
from django.utils import timezone


class Category(models.Model):
    name = models.CharField(max_length=100)
    slug = models.SlugField(max_length=120, unique=True)
    icon = models.CharField(max_length=100, blank=True, help_text="Icon class or URL")

    class Meta:
        verbose_name_plural = "Categories"
        ordering = ["name"]

    def __str__(self) -> str:
        return self.name


class Show(models.Model):
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    cover_image = models.URLField(blank=True)
    host_name = models.CharField(max_length=200)
    schedule_time = models.DateTimeField()
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name="shows")
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["schedule_time"]

    def __str__(self) -> str:
        return self.title


class Episode(models.Model):
    show = models.ForeignKey(Show, on_delete=models.CASCADE, related_name="episodes")
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    audio_file = models.FileField(upload_to="episodes/")
    duration = models.PositiveIntegerField(help_text="Duration in seconds")
    published_at = models.DateTimeField(default=timezone.now)
    play_count = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["-published_at"]

    def __str__(self) -> str:
        return f"{self.show.title} - {self.title}"


class LiveStreamConfig(models.Model):
    stream_url = models.URLField()
    is_live = models.BooleanField(default=False)
    current_title = models.CharField(max_length=200, blank=True)
    current_host = models.CharField(max_length=200, blank=True)
    banner_message = models.CharField(max_length=255, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Live Stream Config"
        verbose_name_plural = "Live Stream Configs"

    def __str__(self) -> str:
        return f"Live Stream {'ON' if self.is_live else 'OFF'}"


class Announcement(models.Model):
    TYPE_BANNER = "banner"
    TYPE_EMERGENCY_TICKER = "emergency_ticker"
    TYPE_POPUP = "popup"
    TYPE_CHOICES = [
        (TYPE_BANNER, "Banner"),
        (TYPE_EMERGENCY_TICKER, "Emergency Ticker"),
        (TYPE_POPUP, "Popup"),
    ]

    title = models.CharField(max_length=200)
    message = models.TextField()
    type = models.CharField(max_length=20, choices=TYPE_CHOICES, default=TYPE_BANNER)
    is_active = models.BooleanField(default=True)
    start_time = models.DateTimeField()
    end_time = models.DateTimeField()

    class Meta:
        ordering = ["-start_time"]

    def __str__(self) -> str:
        return self.title
