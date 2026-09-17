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
# Python script. The script encrypts them and pushes to Shoutcast.
output.external(
  processed_audio,
  %mp3(bitrate = 320),
  restart_on_crash = true,
  "python3 /opt/radio/encrypt_and_forward.py"
)
