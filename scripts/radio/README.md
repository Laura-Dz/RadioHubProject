# RadioHub Distributed Stream Encryption Architecture

This directory contains the studio encoder pipeline for streaming audio securely from a remote studio computer to the central Django / Shoutcast VPS.

---

## 1. Architecture Flow

```
[ Studio PC ]
  Mixxx DJ
    │ (Broadcasts MP3 / OGG to localhost:8005)
    ▼
  Liquidsoap (`encoder.liq`)
    │ (Audio processing, normalization, encoding)
    ▼
  `output.external` (Pipes raw MP3 to stdin)
    │
    ▼
  `encrypt_and_forward.py`
    │ 1. Fetches AES-128 key dynamically over HTTPS from Django:
    │    POST /api/internal/stream-key/<radio_id>/
    │    Header: X-Station-Key: <station_api_key>
    │ 2. Encrypts MP3 stream using AES-128-CBC
    ▼
  Shoutcast / Icecast Server (TCP 8000 on VPS)
    │ (Relays encrypted bytes — Shoutcast never sees raw audio)
    ▼
[ Cloud VPS ]
  Django Backend (`/api/stream/<radio_id>/`)
    │ 1. Fetches encrypted stream from Shoutcast
    │ 2. Decrypts on-the-fly using station AES-128 key
    │ 3. Streams clean MP3 audio over HTTPS to apps
    ▼
[ Listener Apps (Flutter / Web) ]
```

---

## 2. Setting Up on Central Django Server

### Provision a Station Key
Run the Django management command to generate station credentials:

```bash
python manage.py provision_station_key <radio_id> --name "Station Display Name"
```

Example:
```bash
python manage.py provision_station_key radio_douala --name "Radio Douala Live"
```

Output:
```
Created new stream credentials for station 'radio_douala':
  Radio ID:        radio_douala
  Station Name:    Radio Douala Live
  Station API Key: xvgfrchxltfq_CVtulzX1Z7fzsuMwKijWk8XvJ08VGg
  AES Key (Hex):   76d3fe264265878f6e343e49f7de9874
  Status:          Active

Set these environment variables on the studio encoder PC:
  export RADIO_ID="radio_douala"
  export STATION_API_KEY="xvgfrchxltfq_CVtulzX1Z7fzsuMwKijWk8XvJ08VGg"
  export DJANGO_API_URL="https://your-django-domain.com"
```

### Rotating a Station AES Key
To rotate a station's AES key without re-entering credentials:
```bash
python manage.py provision_station_key radio_douala --rotate
```

---

## 3. Setting Up on Studio PC (Liquidsoap Machine)

### Environment Variables
Configure `/etc/environment` or `.env` on the studio computer:

```bash
# Central Django Server
export DJANGO_API_URL="https://your-django-domain.com"
export RADIO_ID="radio_douala"
export STATION_API_KEY="<api_key_from_provision_step>"

# Shoutcast Server (IP/domain of your VPS)
export SHOUTCAST_HOST="vps.yourdomain.com"
export SHOUTCAST_PORT="8000"
export SHOUTCAST_SOURCE_PASSWORD="your_shoutcast_source_password"
export SHOUTCAST_MOUNT="/stream"
```

### Running the Encoder
```bash
liquidsoap /opt/radio/encoder.liq
```

When `encrypt_and_forward.py` starts, it automatically calls `DJANGO_API_URL` to fetch the current AES-128 key into memory. If the network drops momentarily, it can fall back to `/opt/radio/current.key`.

---

## 4. Listener Audio Playback
Listeners connect to Django's authenticated/metered audio stream endpoint:

```
GET https://your-django-domain.com/api/stream/<radio_id>/
```

Django decrypts the incoming ciphertext chunks from Shoutcast and delivers real-time MP3 audio directly to the Flutter app.
