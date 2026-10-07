from django.core.management.base import BaseCommand
from listener_api.views import process_lapsed_subscriptions_escrow


class Command(BaseCommand):
    help = "Processes automatic escrow refunds for stations whose subscriptions lapsed past the 72-hour grace period."

    def handle(self, *args, **options):
        self.stdout.write(self.style.NOTICE("Checking for lapsed radio subscriptions past 72-hour grace period..."))
        result = process_lapsed_subscriptions_escrow()
        
        status = result.get("status")
        if status == "success":
            refunded = result.get("refunded_announcements", 0)
            radios = result.get("radios_affected", 0)
            self.stdout.write(
                self.style.SUCCESS(
                    f"Successfully processed lapsed escrow refunds: {refunded} announcements refunded across {radios} radios."
                )
            )
        else:
            self.stdout.write(
                self.style.WARNING(f"Escrow processing notice/error: {result.get('message')}")
            )
