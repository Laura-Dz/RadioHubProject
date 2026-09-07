"""
Firebase Admin SDK initialization module.

Supports two initialization methods:
1. GOOGLE_APPLICATION_CREDENTIALS - path to service account JSON file
2. Individual env vars: FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY

Handles newline-escaped private keys safely and prevents duplicate initialization.
"""

import os
import firebase_admin
from firebase_admin import credentials, firestore, auth, storage
from django.conf import settings


_firebase_app = None
_firestore_db = None
_firebase_auth = None
_firebase_storage = None


def _get_credential() -> credentials.Certificate:
    """
    Return Firebase credentials from either:
    - GOOGLE_APPLICATION_CREDENTIALS env var (file path), or
    - Individual FIREBASE_* env vars.
    """
    # Method 1: ADC via GOOGLE_APPLICATION_CREDENTIALS
    google_creds_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS", "").strip()
    if google_creds_path:
        if not os.path.isfile(google_creds_path):
            raise FileNotFoundError(
                f"GOOGLE_APPLICATION_CREDENTIALS points to missing file: {google_creds_path}"
            )
        return credentials.Certificate(google_creds_path)

    # Method 2: Individual env vars
    project_id = os.environ.get("FIREBASE_PROJECT_ID", "").strip()
    client_email = os.environ.get("FIREBASE_CLIENT_EMAIL", "").strip()
    private_key_raw = os.environ.get("FIREBASE_PRIVATE_KEY", "")

    if not project_id or not client_email or not private_key_raw:
        raise EnvironmentError(
            "Firebase credentials not found. Set either GOOGLE_APPLICATION_CREDENTIALS "
            "or FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, and FIREBASE_PRIVATE_KEY."
        )

    # Handle escaped newlines from .env files or shell exports.
    # If the key contains literal \n sequences, convert them to real newlines.
    private_key = private_key_raw.replace("\\n", "\n")

    cred_dict = {
        "type": "service_account",
        "project_id": project_id,
        "private_key_id": os.environ.get("FIREBASE_PRIVATE_KEY_ID", ""),
        "private_key": private_key,
        "client_email": client_email,
        "client_id": os.environ.get("FIREBASE_CLIENT_ID", ""),
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url": os.environ.get("FIREBASE_CLIENT_CERT_URL", ""),
    }

    return credentials.Certificate(cred_dict)


def initialize_firebase() -> firebase_admin.App:
    """
    Initialize the Firebase Admin SDK once.
    Returns the existing app if already initialized.
    """
    global _firebase_app, _firestore_db, _firebase_auth, _firebase_storage

    if _firebase_app is not None:
        return _firebase_app

    # Avoid duplicate initialization across multiple imports/threads
    try:
        _firebase_app = firebase_admin.get_app()
    except ValueError:
        cred = _get_credential()
        _firebase_app = firebase_admin.initialize_app(
            cred,
            {
                "storageBucket": os.environ.get(
                    "FIREBASE_STORAGE_BUCKET",
                    getattr(settings, "FIREBASE_STORAGE_BUCKET", None),
                ),
            },
        )

    # Initialize service references
    _firestore_db = firestore.client(_firebase_app)
    _firebase_auth = auth.Client(_firebase_app)

    bucket_name = os.environ.get(
        "FIREBASE_STORAGE_BUCKET",
        getattr(settings, "FIREBASE_STORAGE_BUCKET", None),
    )
    if bucket_name:
        _firebase_storage = storage.bucket(bucket_name, app=_firebase_app)

    return _firebase_app


def get_firestore_db():
    """Return the Firestore client."""
    if _firestore_db is None:
        initialize_firebase()
    return _firestore_db


def get_firebase_auth():
    """Return the Firebase Auth client."""
    if _firebase_auth is None:
        initialize_firebase()
    return _firebase_auth


def get_firebase_storage():
    """Return the Firebase Storage bucket, or None if not configured."""
    if _firebase_storage is None:
        initialize_firebase()
    return _firebase_storage
