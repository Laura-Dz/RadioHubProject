"""
Seed script for Radio Maria.
Run: python scripts/seed_radio_maria.py
Requires GOOGLE_APPLICATION_CREDENTIALS env var pointing to a service account JSON.
"""
import os
import random
from datetime import datetime, timedelta
from google.cloud import firestore

random.seed(42)

if not os.environ.get('GOOGLE_APPLICATION_CREDENTIALS'):
    default_key = os.path.join(os.path.dirname(__file__), '..', 'Hub', 'serviceAccountKey.json')
    if os.path.exists(default_key):
        os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = os.path.abspath(default_key)

db = firestore.Client()
NOW = datetime.utcnow()

RADIO_ID = 'radio_maria'
RADIO_NAME = 'Radio Maria'


def seed_radio():
    db.collection('radios').document(RADIO_ID).set({
        'name': RADIO_NAME,
        'description': 'A Christian voice in your home, sharing prayers, inspirational messages, faith, and spiritual community.',
        'logoUrl': 'https://picsum.photos/seed/radiomaria/200/200.png',
        'bannerUrl': 'https://picsum.photos/seed/radiomaria_banner/1600/400.png',
        'contactEmail': 'contact@radiomaria.cm',
        'contactPhone': '+237 6 70 00 00 00',
        'website': 'https://radiomaria.cm',
        'location': 'Yaoundé, Cameroon',
        'language': 'fr',
        'categories': ['Spiritual', 'Community', 'Faith', 'Culture'],
        'tags': ['faith', 'prayer', 'spirituality', 'community', 'family', 'gospel'],
        'socialLinks': ['https://facebook.com/radiomariacameroon'],
        'isActive': True,
        'status': 'live',
        'isLive': True,
        'listenerCount': 3120,
        'followerCount': 4850,
        'rating': 4.9,
        'balance': 245000.0,
        'legalStatus': 'nonProfit',
        'createdAt': firestore.SERVER_TIMESTAMP,
        'lastActive': firestore.SERVER_TIMESTAMP,
    }, merge=True)


def seed_staff():
    users = [
        {
            'uid': 'admin_maria_001',
            'displayName': 'Father Jean-Paul',
            'email': 'admin@radiomaria.cm',
            'role': 'radio_admin',
            'radioId': RADIO_ID,
            'radioName': RADIO_NAME,
            'status': 'active',
            'isActive': True,
        },
        {'uid': 'host_claire', 'displayName': 'Sister Claire',   'email': 'claire@radiomaria.cm',  'role': 'host', 'specialty': 'prayer_and_meditation', 'experienceYears': 8},
        {'uid': 'host_marc',   'displayName': 'Marc Antoine',    'email': 'marc@radiomaria.cm',    'role': 'host', 'specialty': 'youth_and_faith',       'experienceYears': 4},
        {'uid': 'host_therese','displayName': 'Thérèse Biya',    'email': 'therese@radiomaria.cm', 'role': 'host', 'specialty': 'community_solidarity', 'experienceYears': 6},
        {'uid': 'tech_gabriel','displayName': 'Gabriel Mbida',   'email': 'gabriel@radiomaria.cm', 'role': 'technician'},
    ]
    for u in users:
        doc = {**u, 'createdAt': firestore.SERVER_TIMESTAMP}
        if u['role'] != 'radio_admin':
            doc['radioId'] = RADIO_ID
            doc['radioName'] = RADIO_NAME
            doc['status'] = 'active'
            doc['isActive'] = True
        db.collection('users').document(u['uid']).set(doc, merge=True)


PROGRAMS = [
    {
        'id': 'prog_morning_prayer',
        'name': 'Morning Prayers & Rosary',
        'host': 'host_claire',
        'hostName': 'Sister Claire',
        'slot': '06:00–08:00',
        'category': 'prayer',
        'format': 'spiritual_reflection',
        'tone': 'peaceful',
        'register': 'formal',
        'targetListeners': 3200,
        'targetAge': {'18_24': 0.08, '25_34': 0.18, '35_44': 0.28, '45_54': 0.24, '55_plus': 0.22},
        'completionRate': 0.88,
        'engagement': 450,
        'topics': ['Daily Rosary', 'Gospel Readings', 'Morning Blessings'],
    },
    {
        'id': 'prog_faith_in_action',
        'name': 'Faith in Action',
        'host': 'host_therese',
        'hostName': 'Thérèse Biya',
        'slot': '10:00–12:00',
        'category': 'community',
        'format': 'call_in_interview',
        'tone': 'uplifting',
        'register': 'neutral',
        'targetListeners': 2100,
        'targetAge': {'18_24': 0.12, '25_34': 0.26, '35_44': 0.32, '45_54': 0.20, '55_plus': 0.10},
        'completionRate': 0.76,
        'engagement': 340,
        'topics': ['Community solidarity', 'Health & family support', 'Youth education'],
    },
    {
        'id': 'prog_evening_chimes',
        'name': 'Evening Gospel & Peace',
        'host': 'host_marc',
        'hostName': 'Marc Antoine',
        'slot': '18:00–20:00',
        'category': 'gospel_music',
        'format': 'music_and_reflection',
        'tone': 'calm',
        'register': 'neutral',
        'targetListeners': 2800,
        'targetAge': {'18_24': 0.22, '25_34': 0.30, '35_44': 0.26, '45_54': 0.14, '55_plus': 0.08},
        'completionRate': 0.82,
        'engagement': 290,
        'topics': ['Gospel hymns', 'Evening meditation', 'Listener intentions'],
    },
]


def seed_programs():
    for p in PROGRAMS:
        db.collection('programs').document(p['id']).set({
            'name': p['name'],
            'radioId': RADIO_ID,
            'radioName': RADIO_NAME,
            'hostId': p['host'],
            'hostName': p['hostName'],
            'slot': p['slot'],
            'category': p['category'],
            'defaultDuration': 7200,
            'isActive': True,
            'createdAt': firestore.SERVER_TIMESTAMP,
        }, merge=True)


def seed_tariffs():
    categories = ['prayer_intention', 'birthday', 'thanksgiving', 'condolence', 'general']
    for i, c in enumerate(categories):
        db.collection('announcement_tariffs').add({
            'radioId': RADIO_ID,
            'category': c,
            'ratePer15SecUnit': 50 + i * 20,
            'ratePerSecond': 5.0,
            'ratePerWord': 3.0,
            'diffusionMultiplier': 0.2,
            'minimumPrice': 500.0,
            'currency': 'XAF',
            'isActive': True,
            'updatedAt': firestore.SERVER_TIMESTAMP,
        })


def run():
    print(f'Seeding {RADIO_NAME} ({RADIO_ID})...')
    seed_radio()
    print('  · radio seeded')
    seed_staff()
    print('  · staff seeded')
    seed_programs()
    print('  · programs seeded')
    seed_tariffs()
    print('  · tariffs seeded')
    print('Done.')


if __name__ == '__main__':
    run()
