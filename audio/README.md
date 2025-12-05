# Audio Directory

This directory contains all audio assets for Salamander Wing.

## Structure

- `sfx/` - Sound effects (lasers, explosions, UI)
- `music/` - Background music loops
- `vo/` - Voice over clips (generated via ElevenLabs)

## Required SFX Files

Place `.ogg` files with these names in `sfx/`:

- `player_laser.ogg` - Player weapon fire
- `enemy_laser.ogg` - Enemy weapon fire
- `explosion_small.ogg` - Enemy death explosion
- `explosion_large.ogg` - Player/carrier death
- `shield_hit.ogg` - Player takes damage
- `carrier_hit.ogg` - Carrier takes damage
- `ui_blip.ogg` - UI interaction sounds
- `alarm_low_carrier.ogg` - Warning alarm for critical carrier

## Required Music Files

Place looping `.ogg` files in `music/`:

- `loop_sortie.ogg` - Combat music loop

## Generating VO

Run the Python script to generate voice clips:

```bash
cd tools
python generate_vo_barks.py
```

This requires:
- `ELEVEN_LABS_KEY` environment variable set
- Python 3 with `requests` library
