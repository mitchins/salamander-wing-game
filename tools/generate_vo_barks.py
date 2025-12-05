#!/usr/bin/env python3
"""
Generate VO barks using ElevenLabs API.
Reads from data/vo_lines.json and outputs OGG files to audio/vo/

Usage:
    python tools/generate_vo_barks.py

Requires:
    - ELEVEN_LABS_KEY environment variable (or in .env file)
    - requests library: pip install requests
    - python-dotenv library (optional): pip install python-dotenv
"""

import os
import sys
import json
import pathlib

try:
    import requests
except ImportError:
    print("Error: requests library required. Install with: pip install requests")
    sys.exit(1)

# Try to load .env file if python-dotenv is available
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass  # dotenv not required if env var is set directly

# Get API key from environment
API_KEY = os.environ.get("ELEVEN_LABS_KEY")
if not API_KEY:
    print("Error: ELEVEN_LABS_KEY environment variable not set")
    print("Set it in your shell or create a .env file with: ELEVEN_LABS_KEY=your_key_here")
    sys.exit(1)

# Voice IDs for each character - replace these with your actual ElevenLabs voice IDs
# You can find voice IDs in the ElevenLabs voice library or by using their API
VOICE_MAP = {
    "RIDER": "pNInz6obpgDQGcFmaJgB",   # Adam - young male protagonist
    "RAZOR": "VR6AewLTigWG4xSOukaG",   # Arnold - cocky wingman
    "STONE": "ErXwobaYiN019PkySvjV",   # Antoni - gruff commander
    "SPARKS": "MF3mGyEYCl7XYWbV9V6O",  # Elli - sarcastic mechanic (female)
    "VERA": "21m00Tcm4TlvDq8ikWAM",    # Rachel - calm AI/ops officer (female)
}

BASE_URL = "https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"

# Voice settings for radio/military feel
VOICE_SETTINGS = {
    "stability": 0.55,
    "similarity_boost": 0.75,
    "style": 0.0,
    "use_speaker_boost": True
}


def get_project_root():
    """Get the project root directory (parent of tools/)"""
    script_dir = pathlib.Path(__file__).parent
    return script_dir.parent


def generate_all():
    """Generate all VO barks from the vo_lines.json spec"""
    project_root = get_project_root()
    
    # Load VO line spec
    vo_lines_path = project_root / "data" / "vo_lines.json"
    if not vo_lines_path.exists():
        print(f"Error: VO lines spec not found at {vo_lines_path}")
        sys.exit(1)
    
    with open(vo_lines_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    # Create output directory
    out_dir = project_root / "audio" / "vo"
    out_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"Generating {len(data)} VO barks...")
    print(f"Output directory: {out_dir}")
    print("-" * 50)
    
    success_count = 0
    error_count = 0
    
    for entry in data:
        vid = entry["id"]
        speaker = entry["speaker"]
        text = entry["text"]
        
        # Check if speaker has a voice assigned
        if speaker not in VOICE_MAP:
            print(f"⚠ Skipping {vid}: No voice mapped for speaker '{speaker}'")
            error_count += 1
            continue
        
        voice_id = VOICE_MAP[speaker]
        output_path = out_dir / f"{vid}.ogg"
        
        # Skip if already exists (remove this check to regenerate)
        if output_path.exists():
            print(f"✓ {vid} (already exists)")
            success_count += 1
            continue
        
        print(f"▸ Generating {vid} ({speaker}): \"{text[:40]}...\"")
        
        try:
            resp = requests.post(
                BASE_URL.format(voice_id=voice_id),
                headers={
                    "xi-api-key": API_KEY,
                    "Accept": "audio/ogg",
                    "Content-Type": "application/json"
                },
                json={
                    "text": text,
                    "model_id": "eleven_turbo_v2_5",
                    "voice_settings": VOICE_SETTINGS
                },
                timeout=30
            )
            resp.raise_for_status()
            
            # Write the audio file
            output_path.write_bytes(resp.content)
            print(f"  ✓ Saved to {output_path.name}")
            success_count += 1
            
        except requests.exceptions.HTTPError as e:
            print(f"  ✗ HTTP error: {e}")
            if resp.text:
                print(f"    Response: {resp.text[:200]}")
            error_count += 1
        except requests.exceptions.RequestException as e:
            print(f"  ✗ Request error: {e}")
            error_count += 1
        except Exception as e:
            print(f"  ✗ Error: {e}")
            error_count += 1
    
    print("-" * 50)
    print(f"Complete: {success_count} succeeded, {error_count} failed")
    
    if error_count > 0:
        sys.exit(1)


def list_voices():
    """List available ElevenLabs voices (useful for finding voice IDs)"""
    print("Fetching available voices...")
    
    resp = requests.get(
        "https://api.elevenlabs.io/v1/voices",
        headers={"xi-api-key": API_KEY},
        timeout=30
    )
    resp.raise_for_status()
    
    voices = resp.json().get("voices", [])
    print(f"\nFound {len(voices)} voices:\n")
    
    for voice in voices:
        print(f"  {voice['name']}")
        print(f"    ID: {voice['voice_id']}")
        labels = voice.get("labels", {})
        if labels:
            print(f"    Labels: {labels}")
        print()


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--list-voices":
        list_voices()
    else:
        generate_all()
