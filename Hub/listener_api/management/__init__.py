from django.core.management.base import BaseCommand
from firebase_admin_config import get_firestore_db, get_firebase_auth


class Command(BaseCommand):
    help = "Verify Firebase Admin SDK connectivity to Firestore and Auth."

    def handle(self, *args, **options):
        self.stdout.write("🔍 Testing Firebase Admin SDK...")

        # Test Firestore
        try:
            db = get_firestore_db()
            collections = list(db.collections())
            self.stdout.write(
                self.style.SUCCESS(
                    f"✅ Firestore connected. Top-level collections: {len(collections)}"
                )
            )
            for col in collections[:5]:
                self.stdout.write(f"   - {col.id}")
        except Exception as exc:
            self.stdout.write(self.style.ERROR(f"❌ Firestore error: {exc}"))

        # Test Auth
        try:
            auth_client = get_firebase_auth()
            # List a small page of users to verify auth works
            page = auth_client.list_users(max_results=1)
            user_count = 0
            for user in page.users:
                user_count += 1
                self.stdout.write(f"   👤 Sample user: {user.uid}")
            self.stdout.write(
                self.style.SUCCESS(f"✅ Auth connected. Users accessible: {user_count > 0}")
            )
        except Exception as exc:
            self.stdout.write(self.style.ERROR(f"❌ Auth error: {exc}"))

        self.stdout.write("Done.")
