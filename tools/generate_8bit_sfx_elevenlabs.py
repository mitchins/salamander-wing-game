#!/usr/bin/env python3
"""Generate 8-bit DOS-style SFX and music using ElevenLabs API"""

import os
import json
import requests
from dotenv import load_dotenv

# Load env vars
load_dotenv('/Users/mitchellcurrie/Projects/salamander-wing-game/.env')
ELEVEN_LABS_KEY = os.getenv('ELEVEN_LABS_KEY')
ELEVEN_LABS_API = 'https://api.elevenlabs.io/v1/sound-generation'

# 8-bit DOS sound effect descriptions
SFX_SPECS = {
    'player_laser.mp3': {
        'text': 'Retro 8-bit arcade laser sound. Sharp descending pitch from high to low frequencies, like Space Invaders. Quick attack, about 200 milliseconds. Square wave quality. Perfect for a 1994 DOS space shooter.',
        'duration_seconds': 1
    },
    'enemy_laser.mp3': {
        'text': 'Retro 8-bit arcade enemy laser sound. Higher pitch than player laser, ascending then descending. Sharp crisp square wave, reminiscent of classic video game sound effects. 150 milliseconds duration.',
        'duration_seconds': 1
    },
    'explosion_small.mp3': {
        'text': '8-bit retro small explosion sound effect. Short burst of noise with descending pitch. Like a small explosion in a 1994 DOS space shooter game. Square wave with quick decay. About 300 milliseconds.',
        'duration_seconds': 1
    },
    'explosion_large.mp3': {
        'text': '8-bit retro large explosion sound effect. Deep booming noise with heavy bass frequencies descending quickly. Longer duration, about 500ms. Sounds like a big ship being hit in a DOS game from 1994.',
        'duration_seconds': 1
    },
    'shield_hit.mp3': {
        'text': 'Retro 8-bit shield impact sound. Quick descending beep sequence, like a shield being hit. Three short tones going down in pitch. Square wave. Crisp and punchy, about 100 milliseconds.',
        'duration_seconds': 1
    },
    'carrier_hit.mp3': {
        'text': 'Retro 8-bit alarm sound for carrier damage. Rising pitch alarm tone, multiple beeps in sequence. Urgent sounding. Like a damage warning in a 1994 DOS space game. Square wave.',
        'duration_seconds': 2
    },
    'ui_blip.mp3': {
        'text': 'Simple retro 8-bit menu selection beep. Two quick high-pitched tones, like selecting a menu item. Very short, about 50 milliseconds total. Crisp and clean.',
        'duration_seconds': 1
    },
    'alarm_low_carrier.mp3': {
        'text': 'Retro 8-bit warning alarm for low carrier. Repeating double-beep pattern. Urgent but not as intense as red alert. Square wave at medium pitch. Loops naturally. DOS game aesthetic.',
        'duration_seconds': 3
    },
}

MUSIC_SPECS = {
    'loop_sortie.mp3': {
        'text': 'Retro 8-bit DOS combat theme music loop. Upbeat action music with simple square wave melody and bass line. 4 seconds, loops seamlessly. Sounds like Wing Commander or similar 1994 space shooter soundtrack. Electronic synth instruments.',
        'duration_seconds': 4
    },
}

def generate_sound(filename, spec, output_dir):
    """Generate a sound using ElevenLabs API"""
    try:
        headers = {
            'xi-api-key': ELEVEN_LABS_KEY,
            'Content-Type': 'application/json'
        }
        
        payload = {
            'text': spec['text'],
            'duration_seconds': spec['duration_seconds']
        }
        
        print(f"  Generating {filename}...", end=' ', flush=True)
        response = requests.post(
            ELEVEN_LABS_API,
            headers=headers,
            json=payload,
            timeout=60
        )
        
        if response.status_code == 200:
            output_path = os.path.join(output_dir, filename)
            with open(output_path, 'wb') as f:
                f.write(response.content)
            print("✓")
            return True
        else:
            print(f"✗ (HTTP {response.status_code})")
            print(f"    Response: {response.text}")
            return False
    except Exception as e:
        print(f"✗ Error: {e}")
        return False

def generate_all():
    """Generate all SFX and music"""
    if not ELEVEN_LABS_KEY:
        print("ERROR: ELEVEN_LABS_KEY not found in .env")
        return False
    
    dirs = {
        'sfx': '/Users/mitchellcurrie/Projects/salamander-wing-game/audio/sfx',
        'music': '/Users/mitchellcurrie/Projects/salamander-wing-game/audio/music'
    }
    
    for d in dirs.values():
        os.makedirs(d, exist_ok=True)
    
    print("Generating 8-bit SFX via ElevenLabs...")
    sfx_success = 0
    for filename, spec in SFX_SPECS.items():
        if generate_sound(filename, spec, dirs['sfx']):
            sfx_success += 1
    
    print(f"\nGenerating 8-bit music via ElevenLabs...")
    music_success = 0
    for filename, spec in MUSIC_SPECS.items():
        if generate_sound(filename, spec, dirs['music']):
            music_success += 1
    
    total = len(SFX_SPECS) + len(MUSIC_SPECS)
    completed = sfx_success + music_success
    
    print(f"\n✓ Generated {completed}/{total} audio files")
    return completed == total

if __name__ == '__main__':
    success = generate_all()
    exit(0 if success else 1)
