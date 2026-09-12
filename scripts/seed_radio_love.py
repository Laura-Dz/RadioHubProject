"""
Seed script for Radio Love.
Run: python scripts/seed_radio_love.py
Requires GOOGLE_APPLICATION_CREDENTIALS env var pointing to a service account JSON.
"""
import os
import random
from datetime import datetime, timedelta
from google.cloud import firestore

random.seed(42)  # reproducible

if not os.environ.get('GOOGLE_APPLICATION_CREDENTIALS'):
    default_key = os.path.join(os.path.dirname(__file__), '..', 'Hub', 'serviceAccountKey.json')
    if os.path.exists(default_key):
        os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = os.path.abspath(default_key)

db = firestore.Client()
NOW = datetime.utcnow()

RADIO_ID = 'radio_love'
RADIO_NAME = 'Radio Love'


# ============================================================
# 1. RADIO
# ============================================================

def seed_radio():
    db.collection('radios').document(RADIO_ID).set({
        'name': RADIO_NAME,
        'description': 'Music, conversations, and stories about love, relationships, and everyday life.',
        'logoUrl': 'https://picsum.photos/seed/radiolove/200/200',
        'bannerUrl': 'https://picsum.photos/seed/radiolove_banner/1600/400',
        'contactEmail': 'contact@radiolove.cm',
        'contactPhone': '+237 6 99 00 00 00',
        'website': 'https://radiolove.cm',
        'location': 'Douala, Cameroon',
        'language': 'fr',
        'tags': ['love', 'relationships', 'family', 'wellness', 'music'],
        'socialLinks': ['https://facebook.com/radiolove'],
        'isActive': True,
        'status': 'live',
        'listenerCount': 2456,
        'balance': 187500.0,
        'createdAt': firestore.SERVER_TIMESTAMP,
    })


# ============================================================
# 2. STAFF (radio admin, hosts, technicians)
# ============================================================

def seed_staff():
    users = [
        # Radio admin
        {
            'uid': 'admin_love_001',
            'displayName': 'Laura B.',
            'email': 'laurab@radiolove.cm',
            'role': 'radio_admin',
            'radioId': RADIO_ID,
            'radioName': RADIO_NAME,
            'status': 'active',
            'isActive': True,
        },
        # Hosts
        {'uid': 'host_sarah',  'displayName': 'Sarah Mbah',    'email': 'sarah@radiolove.cm',   'role': 'host', 'specialty': 'relationships', 'experienceYears': 6},
        {'uid': 'host_david',  'displayName': 'David Ekane',   'email': 'david@radiolove.cm',   'role': 'host', 'specialty': 'lifestyle',     'experienceYears': 3},
        {'uid': 'host_grace',  'displayName': 'Grace Nfor',    'email': 'grace@radiolove.cm',   'role': 'host', 'specialty': 'family',        'experienceYears': 9},
        {'uid': 'host_emma',   'displayName': 'Emma Tchoumi',  'email': 'emma@radiolove.cm',    'role': 'host', 'specialty': 'youth',         'experienceYears': 2},
        # Technicians
        {'uid': 'tech_john',   'displayName': 'John Bakari',   'email': 'john@radiolove.cm',    'role': 'technician'},
        {'uid': 'tech_martin', 'displayName': 'Martin Ngwa',   'email': 'martin@radiolove.cm',  'role': 'technician'},
    ]
    for u in users:
        doc = {**u, 'createdAt': firestore.SERVER_TIMESTAMP}
        if u['role'] != 'radio_admin':
            doc['radioId'] = RADIO_ID
            doc['radioName'] = RADIO_NAME
            doc['status'] = 'active'
            doc['isActive'] = True
        db.collection('users').document(u['uid']).set(doc, merge=True)


# ============================================================
# 3. PROGRAMS / SHOWS
# ============================================================
# Each program has a "design intent" that drives its seeded sessions.
# Mid-Day Talk is the anchor (broad age appeal).
# Afternoon Chill is the underperformer (young, narrow).
# Others fill the middle.

PROGRAMS = [
    {
        'id': 'prog_midday',
        'name': 'Mid-Day Talk',
        'host': 'host_sarah',
        'hostName': 'Sarah Mbah',
        'slot': '12:00–14:00',
        'category': 'relationships',
        'format': 'call_in_interview',
        'tone': 'uplifting',
        'register': 'neutral',
        'targetListeners': 2400,
        'targetAge': {'18_24': 0.12, '25_34': 0.28, '35_44': 0.31, '45_54': 0.18, '55_plus': 0.11},
        'completionRate': 0.78,
        'engagement': 320,
        'topics': ['Finding love after 40', 'Everyday relationship wins', 'Family & work balance'],
    },
    {
        'id': 'prog_morning_letters',
        'name': 'Morning Love Letters',
        'host': 'host_grace',
        'hostName': 'Grace Nfor',
        'slot': '08:00–10:00',
        'category': 'family',
        'format': 'call_in',
        'tone': 'nostalgic',
        'register': 'neutral',
        'targetListeners': 1900,
        'targetAge': {'18_24': 0.10, '25_34': 0.24, '35_44': 0.30, '45_54': 0.22, '55_plus': 0.14},
        'completionRate': 0.72,
        'engagement': 280,
        'topics': ['Old love letters', 'Family stories', 'Community memories'],
    },
    {
        'id': 'prog_love_money',
        'name': 'Love & Money',
        'host': 'host_david',
        'hostName': 'David Ekane',
        'slot': '16:00–18:00',
        'category': 'lifestyle',
        'format': 'interview',
        'tone': 'serious',
        'register': 'neutral',
        'targetListeners': 1350,
        'targetAge': {'18_24': 0.15, '25_34': 0.30, '35_44': 0.28, '45_54': 0.17, '55_plus': 0.10},
        'completionRate': 0.68,
        'engagement': 190,
        'topics': ['Budgeting as a couple', 'Career vs family'],
    },
    {
        'id': 'prog_heart_to_heart',
        'name': 'Heart to Heart',
        'host': 'host_sarah',
        'hostName': 'Sarah Mbah',
        'slot': '20:00–22:00',
        'category': 'relationships',
        'format': 'call_in',
        'tone': 'uplifting',
        'register': 'neutral',
        'targetListeners': 1600,
        'targetAge': {'18_24': 0.18, '25_34': 0.32, '35_44': 0.28, '45_54': 0.14, '55_plus': 0.08},
        'completionRate': 0.74,
        'engagement': 240,
        'topics': ['Confessions', 'Advice from listeners'],
    },
    {
        'id': 'prog_afternoon_chill',
        'name': 'Afternoon Chill',
        'host': 'host_emma',
        'hostName': 'Emma Tchoumi',
        'slot': '14:00–16:00',
        'category': 'youth',
        'format': 'music_mix',
        'tone': 'casual',
        'register': 'slang',
        'targetListeners': 720,
        'targetAge': {'18_24': 0.62, '25_34': 0.28, '35_44': 0.06, '45_54': 0.03, '55_plus': 0.01},
        'completionRate': 0.42,
        'engagement': 110,
        'topics': ['Gaming soundtracks', 'Nightlife anthems', 'Trending tracks'],
    },
    {
        'id': 'prog_sunday_family',
        'name': 'Sunday Family Hour',
        'host': 'host_grace',
        'hostName': 'Grace Nfor',
        'slot': '10:00–12:00 (Sun)',
        'category': 'family',
        'format': 'panel',
        'tone': 'uplifting',
        'register': 'neutral',
        'targetListeners': 1750,
        'targetAge': {'18_24': 0.09, '25_34': 0.20, '35_44': 0.30, '45_54': 0.25, '55_plus': 0.16},
        'completionRate': 0.71,
        'engagement': 260,
        'topics': ['Family values', 'Intergenerational conversations'],
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
        })


# ============================================================
# 4. SESSIONS (past 45 days)
# ============================================================

def seed_sessions():
    """
    For each program, generate ~15 sessions in the past 45 days.
    Listener count = target ± noise. Audience distribution = target ± noise.
    """
    total = 0
    for p in PROGRAMS:
        for i in range(15):
            days_back = random.randint(1, 45)
            start = NOW - timedelta(days=days_back)
            # Parse the slot
            slot_start = p['slot'].split('–')[0].strip().split(':')[0]
            start = start.replace(hour=int(slot_start), minute=0, second=0, microsecond=0)
            end = start + timedelta(hours=2)

            # Simulate performance
            noise = random.uniform(0.85, 1.15)
            listeners = int(p['targetListeners'] * noise)
            completion = round(min(max(p['completionRate'] + random.uniform(-0.08, 0.08), 0), 1), 2)
            engagement = int(p['engagement'] * random.uniform(0.85, 1.15))

            # Audience distribution
            dist = {}
            for k, v in p['targetAge'].items():
                dist[k] = round(max(0, v + random.uniform(-0.03, 0.03)), 3)

            session_id = f"sess_{p['id']}_{days_back}"
            db.collection('sessions').document(session_id).set({
                'radioId': RADIO_ID,
                'programId': RADIO_ID,
                'programShowId': p['id'],
                'programName': p['name'],
                'startTime': start,
                'endTime': end,
                'hostId': p['host'],
                'hostName': p['hostName'],
                'listenerCount': listeners,
                'completionRate': completion,
                'engagementCount': engagement,
                'theme': {
                    'category': p['category'],
                    'specificTopic': random.choice(p['topics']),
                    'isRecurring': True,
                },
                'format': p['format'],
                'tone': p['tone'],
                'languageRegister': p['register'],
                'guestType': 'expert' if 'interview' in p['format'] else 'none',
                'guestCount': 1 if 'interview' in p['format'] else 0,
                'audience': {
                    'ageDistribution': dist,
                    'genderSplit': {'male': 0.42, 'female': 0.56, 'other': 0.02},
                    'topLocations': ['Douala', 'Yaoundé'],
                    'newVsReturning': {'new': 0.18, 'returning': 0.82},
                },
                'status': 'ended',
                'createdAt': start,
            })
            total += 1
    print(f'  · {total} sessions seeded')


# ============================================================
# 5. LISTENER ANALYTICS (hourly samples per session)
# ============================================================

def seed_analytics():
    """
    For each session, write hourly listener_analytics docs.
    This is what feeds the audimat heatmap.
    """
    sessions = db.collection('sessions').where('radioId', '==', RADIO_ID).stream()
    total = 0
    for sess in sessions:
        data = sess.to_dict()
        start = data.get('startTime')
        end = data.get('endTime')
        if not start or not end:
            continue
        listener_count = data.get('listenerCount', 500) or 500
        # Add 1 hour-bucket before the show + 2 during
        cursor = start
        while cursor <= end:
            jitter = random.uniform(0.9, 1.1)
            db.collection('listener_analytics').add({
                'radioId': RADIO_ID,
                'sessionId': sess.id,
                'date': cursor,
                'count': int(listener_count * jitter),
                'ageGroup': None,  # aggregated only at session level
            })
            total += 1
            cursor += timedelta(hours=1)
    print(f'  · {total} analytics points seeded')


# ============================================================
# 6. TARIFFS + TRANSACTIONS (so revenue section works)
# ============================================================

def seed_tariffs():
    categories = ['general', 'birthday', 'anniversary', 'congratulations',
                  'condolence', 'promotional', 'event', 'dedication', 'other']
    for i, c in enumerate(categories):
        db.collection('announcement_tariffs').add({
            'radioId': RADIO_ID,
            'category': c,
            'ratePer15SecUnit': 100 + i * 25,
            'isActive': True,
            'updatedAt': firestore.SERVER_TIMESTAMP,
        })


def seed_transactions():
    # Subscription (3 months of history)
    for i in range(3):
        date = NOW - timedelta(days=30 * (i + 1))
        db.collection('transactions').add({
            'radioId': RADIO_ID,
            'radioName': RADIO_NAME,
            'type': 'subscription',
            'status': 'released',
            'baseAmount': 30000.0,
            'transferFee': 0.0,
            'totalAmount': 30000.0,
            'currency': 'XAF',
            'initiatorId': 'admin_love_001',
            'initiatorName': 'Laura B.',
            'paymentMethod': 'MoMo',
            'createdAt': date,
            'releasedAt': date,
        })

    # Announcement revenue (validated announcements)
    for i in range(8):
        date = NOW - timedelta(days=random.randint(1, 45))
        base = random.choice([3000, 5000, 7500, 10000])
        db.collection('transactions').add({
            'radioId': RADIO_ID,
            'radioName': RADIO_NAME,
            'type': 'announcement',
            'status': 'released',
            'baseAmount': float(base),
            'transferFee': round(base * 0.04, 2),
            'totalAmount': round(base * 1.04, 2),
            'currency': 'XAF',
            'initiatorId': f'listener_{i}',
            'initiatorName': f'Listener {i+1}',
            'paymentMethod': 'OM',
            'createdAt': date,
            'releasedAt': date,
        })


def seed_announcements():
    categories = ['birthday', 'anniversary', 'condolence', 'promotional', 'event']
    for i in range(12):
        cat = random.choice(categories)
        date = NOW - timedelta(days=random.randint(1, 45))
        db.collection('announcements').add({
            'radioId': RADIO_ID,
            'radioName': RADIO_NAME,
            'listenerId': f'listener_{i}',
            'listenerName': f'Listener {i+1}',
            'listenerEmail': f'listener{i+1}@example.com',
            'originalText': f'A short {cat} message.',
            'finalText': f'A heartfelt {cat} message from a listener.',
            'category': cat,
            'wordCount': 12 + i,
            'durationSeconds': 15,
            'diffusionsPerDay': random.randint(1, 3),
            'days': random.randint(1, 5),
            'desiredStartDate': date,
            'baseAmount': 3000.0,
            'transferFee': 120.0,
            'finalPrice': 3120.0,
            'currency': 'XAF',
            'paymentMethod': 'MoMo',
            'status': random.choice(['scheduled', 'rejected', 'printed']),
            'createdAt': date,
        })


# ============================================================
# RUN
# ============================================================

def run():
    print('Seeding Radio Love...')
    print('  · radio')
    seed_radio()
    print('  · staff')
    seed_staff()
    print('  · programs')
    seed_programs()
    print('  · sessions')
    seed_sessions()
    print('  · analytics')
    seed_analytics()
    print('  · tariffs')
    seed_tariffs()
    print('  · transactions')
    seed_transactions()
    print('  · announcements')
    seed_announcements()
    print('Done.')


if __name__ == '__main__':
    run()
