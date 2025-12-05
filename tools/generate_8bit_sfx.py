#!/usr/bin/env python3
"""Generate 8-bit DOS-style SFX and music"""

import os
import numpy as np
from pydub import AudioSegment

SAMPLE_RATE = 22050

def generate_tone(frequency, duration_ms, wave_type='square'):
    """Generate a simple wave tone"""
    duration_sec = duration_ms / 1000.0
    samples = int(SAMPLE_RATE * duration_sec)
    t = np.linspace(0, duration_sec, samples)
    
    if wave_type == 'sine':
        wave = np.sin(2 * np.pi * frequency * t)
    elif wave_type == 'square':
        wave = np.sign(np.sin(2 * np.pi * frequency * t))
    else:
        wave = np.sin(2 * np.pi * frequency * t)
    
    # Envelope
    envelope = np.ones_like(t)
    attack = int(SAMPLE_RATE * 0.01)
    decay = int(SAMPLE_RATE * 0.05)
    if len(t) > attack + decay:
        envelope[:attack] = np.linspace(0, 1, attack)
        envelope[-decay:] = np.linspace(1, 0.2, decay)
    
    wave = wave * envelope
    wave = np.int16(wave * 32767 * 0.8)
    
    audio = AudioSegment(wave.tobytes(), frame_rate=SAMPLE_RATE, sample_width=2, channels=1)
    return audio

# SFX Generators
def player_laser():
    freqs = [800, 750, 700, 650, 600]
    audio = AudioSegment.silent(duration=0)
    for freq in freqs:
        audio += generate_tone(freq, 40, 'square')
    return audio - 3

def enemy_laser():
    freqs = [1200, 1100, 1000, 900]
    audio = AudioSegment.silent(duration=0)
    for freq in freqs:
        audio += generate_tone(freq, 35, 'square')
    return audio - 3

def explosion_small():
    noise = AudioSegment.silent(duration=0)
    for i in range(3):
        freq = 3000 + (i * 500)
        noise += generate_tone(freq, 80, 'square') * 0.4
    for freq in [1500, 1000, 500, 250]:
        noise += generate_tone(freq, 60, 'square') * 0.5
    return noise - 2

def explosion_large():
    explosion = AudioSegment.silent(duration=0)
    for freq in [400, 350, 300, 250]:
        explosion += generate_tone(freq, 100, 'sine')
    for freq in [200, 150, 100]:
        explosion += generate_tone(freq, 80, 'sine') * 0.6
    return explosion - 1

def shield_hit():
    audio = AudioSegment.silent(duration=0)
    audio += generate_tone(1200, 50, 'sine')
    audio += generate_tone(1000, 40, 'sine')
    audio += generate_tone(800, 30, 'sine')
    return audio - 4

def carrier_hit():
    audio = AudioSegment.silent(duration=0)
    for freq in [400, 500, 600, 700]:
        audio += generate_tone(freq, 60, 'square')
    return audio

def ui_blip():
    audio = AudioSegment.silent(duration=0)
    audio += generate_tone(600, 20, 'sine')
    audio += AudioSegment.silent(duration=10)
    audio += generate_tone(800, 20, 'sine')
    return audio - 6

def alarm_low_carrier():
    audio = AudioSegment.silent(duration=0)
    for _ in range(3):
        audio += generate_tone(500, 150, 'square')
        audio += AudioSegment.silent(duration=50)
        audio += generate_tone(500, 150, 'square')
        audio += AudioSegment.silent(duration=200)
    return audio - 2

def sortie_theme():
    theme = AudioSegment.silent(duration=0)
    notes = [(523, 200), (587, 200), (659, 200), (784, 200), (659, 200), (587, 200), (523, 200), (440, 400)]
    for freq, duration in notes:
        theme += generate_tone(freq, duration, 'square')
    
    target_length = 4000
    while len(theme) < target_length:
        theme += theme[:500]
    return theme[:target_length]

def generate_all():
    dirs = {
        'sfx': '/Users/mitchellcurrie/Projects/salamander-wing-game/audio/sfx',
        'music': '/Users/mitchellcurrie/Projects/salamander-wing-game/audio/music'
    }
    
    for d in dirs.values():
        os.makedirs(d, exist_ok=True)
    
    sfx_files = {
        'player_laser.mp3': player_laser(),
        'enemy_laser.mp3': enemy_laser(),
        'explosion_small.mp3': explosion_small(),
        'explosion_large.mp3': explosion_large(),
        'shield_hit.mp3': shield_hit(),
        'carrier_hit.mp3': carrier_hit(),
        'ui_blip.mp3': ui_blip(),
        'alarm_low_carrier.mp3': alarm_low_carrier(),
    }
    
    print("Generating 8-bit SFX...")
    for filename, audio in sfx_files.items():
        path = os.path.join(dirs['sfx'], filename)
        audio.export(path, format='mp3', bitrate='128k')
        print(f"  ✓ {filename}")
    
    print("\nGenerating 8-bit music...")
    music = {'loop_sortie.mp3': sortie_theme()}
    for filename, audio in music.items():
        path = os.path.join(dirs['music'], filename)
        audio.export(path, format='mp3', bitrate='128k')
        print(f"  ✓ {filename}")
    
    print("\n✓ All audio generated!")

if __name__ == '__main__':
    generate_all()
