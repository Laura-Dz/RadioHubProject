import secrets
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


class StationStreamKey(models.Model):
    radio_id = models.CharField(max_length=100, unique=True, db_index=True)
    radio_name = models.CharField(max_length=200, blank=True)
    api_key = models.CharField(max_length=128, unique=True, help_text="Station authorization key for fetching stream AES key")
    aes_key_hex = models.CharField(max_length=64, help_text="AES-128 key in hex (32 hex characters = 16 bytes)")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Station Stream Key"
        verbose_name_plural = "Station Stream Keys"
        ordering = ["radio_id"]

    def __str__(self) -> str:
        return f"{self.radio_name or self.radio_id} ({self.radio_id})"

    def get_aes_bytes(self) -> bytes:
        return bytes.fromhex(self.aes_key_hex)

    def rotate_aes_key(self) -> str:
        self.aes_key_hex = secrets.token_hex(16)
        self.save(update_fields=["aes_key_hex", "updated_at"])
        return self.aes_key_hex

    @classmethod
    def generate_key_pair(cls, radio_id: str, radio_name: str = ""):
        """Utility to generate a new station key entry with random API key and AES-128 key"""
        api_key = secrets.token_urlsafe(32)
        aes_key = secrets.token_hex(16)  # 16 bytes = 32 hex chars
        obj, _ = cls.objects.update_or_create(
            radio_id=radio_id,
            defaults={
                "radio_name": radio_name,
                "api_key": api_key,
                "aes_key_hex": aes_key,
                "is_active": True,
            },
        )
        return obj

