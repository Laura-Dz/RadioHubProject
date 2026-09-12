import json
from google.cloud import storage
from google.oauth2 import service_account

SERVICE_ACCOUNT_PATH = 'Hub/serviceAccountKey.json'
BUCKET_NAME = 'radiohub12.firebasestorage.app'

def set_cors():
    try:
        credentials = service_account.Credentials.from_service_account_file(SERVICE_ACCOUNT_PATH)
        client = storage.Client(project=credentials.project_id, credentials=credentials)
        bucket = client.get_bucket(BUCKET_NAME)

        cors_configuration = [
            {
                "origin": ["*"],
                "method": ["GET", "POST", "PUT", "DELETE", "HEAD", "OPTIONS"],
                "responseHeader": [
                    "Content-Type",
                    "Access-Control-Allow-Origin",
                    "x-goog-resumable"
                ],
                "maxAgeSeconds": 3600
            }
        ]

        bucket.cors = cors_configuration
        bucket.patch()

        print(f"SUCCESS: CORS successfully applied to bucket {BUCKET_NAME}!")
        print("Updated CORS configuration:")
        print(json.dumps(bucket.cors, indent=2))
        return True
    except Exception as e:
        print(f"ERROR applying CORS: {e}")
        return False

if __name__ == '__main__':
    set_cors()
