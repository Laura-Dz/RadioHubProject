from django.core.management.base import BaseCommand
from listener_api.models import StationStreamKey


class Command(BaseCommand):
    help = "Provisions or displays API key and AES stream key for a radio station."

    def add_arguments(self, parser):
        parser.add_argument("radio_id", type=str, help="Unique identifier of the radio station")
        parser.add_argument("--name", type=str, default="", help="Human-readable station name")
        parser.add_argument("--rotate", action="store_true", help="Rotate AES stream key if station already exists")

    def handle(self, *args, **options):
        radio_id = options["radio_id"]
        name = options["name"]
        rotate = options["rotate"]

        station = StationStreamKey.objects.filter(radio_id=radio_id).first()
        if not station:
            station = StationStreamKey.generate_key_pair(radio_id=radio_id, radio_name=name)
            self.stdout.write(self.style.SUCCESS(f"Created new stream credentials for station '{radio_id}':"))
        else:
            if name and name != station.radio_name:
                station.radio_name = name
                station.save(update_fields=["radio_name"])
            if rotate:
                station.rotate_aes_key()
                self.stdout.write(self.style.WARNING(f"Rotated AES key for station '{radio_id}':"))
            else:
                self.stdout.write(self.style.SUCCESS(f"Existing stream credentials for station '{radio_id}':"))

        self.stdout.write(f"  Radio ID:        {station.radio_id}")
        self.stdout.write(f"  Station Name:    {station.radio_name}")
        self.stdout.write(f"  Station API Key: {station.api_key}")
        self.stdout.write(f"  AES Key (Hex):   {station.aes_key_hex}")
        self.stdout.write(f"  Status:          {'Active' if station.is_active else 'Inactive'}")
        self.stdout.write("")
        self.stdout.write(self.style.NOTICE("Set these environment variables on the studio encoder PC:"))
        self.stdout.write(f"  export RADIO_ID=\"{station.radio_id}\"")
        self.stdout.write(f"  export STATION_API_KEY=\"{station.api_key}\"")
        self.stdout.write("  export DJANGO_API_URL=\"https://your-django-domain.com\"")
