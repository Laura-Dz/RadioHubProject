#!/usr/bin/env liquidsoap

# --- SECTION 1: INPUT HARBOR (From Mixxx) ---
live_input = input.harbor("mixxx",
  port = 8005,
  password = "mixxx_to_liquidsoap_password"
)

# --- SECTION 2: AUDIO PROCESSING ---
safe_input = mksafe(live_input)
processed_audio = limit(amplify(1.0, safe_input))

# --- SECTION 3: ENCODE + ENCRYPT + FORWARD TO SHOUTCAST ---
# Liquidsoap encodes the audio to MP3 and pipes the bytes to our
# Python script. The script encrypts them using AES-128-CBC and pushes to Shoutcast.
output.external(
  %mp3(bitrate = 320),
  "python3 /home/laura/Desktop/RadioHubProject/scripts/radio/encrypt_and_forward.py",
  processed_audio
)
