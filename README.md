# Salamander Wing - Rail Shooter Vignette

A **"lovingly shitty 1994 Descent-era"** space rail shooter tech demo built in Godot 4. This project demonstrates authentic low-poly 3D aesthetics running on modern hardware:

- True 3D low-poly ships (not sprites), very simple meshes ~150 triangles
- Flat/simple lighting, tiny color palette, no PBR or modern post-processing
- 480×320 "console" render with tasteful CRT / color banding effects
- Crisp HUD text in neon green / amber 90s debug style

![Godot 4.3+](https://img.shields.io/badge/Godot-4.3+-blue)
![GDScript](https://img.shields.io/badge/Language-GDScript-green)

## The 1994 Aesthetic

This build deliberately targets a **Descent / Wing Commander 3** visual feel:

### What Makes It "1994"
- **No HDR, bloom, or glow** - Linear tonemapping only
- **Flat materials** - `metallic = 0.0`, `roughness = 1.0`, albedo only
- **Tiny palette** - 5-6 solid colors for all ships (muted green, red, yellow, grey, cockpit blue)
- **Simple lighting** - One directional "key" light, no shadows, gentle Gouraud-style gradients
- **Color banding** - CRT shader posterizes to ~16 color levels per channel with ordered dithering
- **Scanlines** - Subtle horizontal darkening every other pixel row
- **Starfield skybox** - Follows camera on a sphere, doesn't zoom, just rotates slowly

### Ships
- **Player**: Chunky nose cone, swept wings, tail fin, twin engines (~120 triangles)
- **Enemy**: Twin-hull "fork" design with forward-swept wings, yellow hazard stripes (~100 triangles)

## Features

- **Complete Vignette Loop**: CINEMATIC → QTE → COMBAT → SUMMARY → repeat
- **Cinematic Autopilot**: Player watches the ship fly while radio chatter plays
- **QTE Decision Points**: Timed choices (EVADE vs HOLD) that alter the dogfight
- **Meaningful Consequences**: QTE choice changes enemy count, speed, and damage profile
- **Combat Windows**: ~18 seconds of hands-on dogfighting
- **Combat Summary**: End-of-window debrief showing damage taken and score gained
- **Time Scale Drama**: Slow-motion during QTE for cinematic tension
- **Camera Shake**: Impact feedback on damage
- **Retro CRT Shader**: Barrel distortion, scanlines, color banding, and vignette
- **Low-Resolution Rendering**: 480×320 SubViewport scaled up for authentic pixel look
- **Chunky HUD**: Shield/score in neon green, chatter in amber, crisp over CRT view

## Requirements

- **Godot 4.3** or later (tested with Godot 4.3)
- No external addons or C# required - pure GDScript

## How to Run

1. Open Godot 4.3+
2. Import this project folder
3. Open `scenes/Main.tscn`
4. Press F5 or click Play

## The Gameplay Loop

The demo cycles through a complete vignette loop:

1. **CINEMATIC** (~8 seconds)
   - Ship flies on autopilot
   - Radio chatter displays on screen ("RAZOR: Stay sharp out there...")
   - Player cannot move or shoot
   - Crosshair hidden

2. **QTE** (~4 seconds timeout)
   - **Time slows to 70%** for dramatic tension
   - Big overlay appears: "EVADE [1]" or "HOLD COURSE [2]"
   - Press 1 or 2 (or click buttons) to choose
   - Choice **meaningfully affects** the combat that follows
   - If timeout expires, defaults to HOLD

3. **COMBAT** (~18 seconds)
   - Full player control restored
   - **EVADE path**: Fewer enemies (max 5), slower (70% speed), but you take 10 damage immediately
   - **HOLD path**: More enemies (max 12), faster (120% speed), higher risk/reward
   - **Camera shakes** on damage for impact
   - Shoot to score points, avoid collisions

4. **SUMMARY** (~3 seconds)
   - Centered panel shows combat results
   - Displays choice made, damage taken, and score gained
   - "RAZOR: Good work, Rider. Returning to formation."
   - Then loops back to CINEMATIC

## Controls

| Action | Keys |
|--------|------|
| Move Up | W / Up Arrow |
| Move Down | S / Down Arrow |
| Move Left | A / Left Arrow |
| Move Right | D / Right Arrow |
| Fire | Space |
| QTE: Evade | 1 |
| QTE: Hold | 2 |

## Project Structure

```
salamander-wing-game/
├── project.godot          # Godot project file with input mappings
├── icon.svg               # Project icon
├── README.md              # This file
│
├── materials/             # 1994-style flat materials (no PBR)
│   ├── mat_player_hull.tres
│   ├── mat_cockpit.tres
│   ├── mat_enemy_red.tres
│   ├── mat_enemy_yellow.tres
│   ├── mat_neutral_grey.tres
│   ├── mat_bullet.tres
│   └── mat_explosion.tres
│
├── scenes/
│   ├── Main.tscn          # Main game scene (run this)
│   ├── Player.tscn        # Player ship (~120 triangles)
│   ├── Enemy.tscn         # Enemy ship (~100 triangles)
│   ├── Bullet.tscn        # Player projectile
│   └── Explosion.tscn     # Explosion particles
│
├── scripts/
│   ├── Main.gd            # State machine + scene controller
│   ├── Player.gd          # Player movement, firing, camera shake
│   ├── Enemy.gd           # Enemy behavior
│   ├── Bullet.gd          # Projectile logic
│   ├── Explosion.gd       # Explosion lifecycle
│   ├── EnemySpawner.gd    # Enemy wave spawning
│   ├── GameController.gd  # Score, shield, game state
│   ├── QTEOverlay.gd      # QTE decision UI
│   ├── HUD.gd             # HUD display logic
│   └── Starfield.gd       # Infinite spherical starfield
│
├── shaders/
│   └── crt.gdshader       # CRT shader with color banding
│
└── ui/
    ├── HUD.tscn           # In-game HUD (neon green stats, amber chatter)
    └── QTEOverlay.tscn    # QTE decision overlay
```

## Tweak Points

### State Machine Timing
In `scripts/Main.gd`:
```gdscript
@export var cinematic_duration: float = 8.0   # Seconds of autopilot
@export var qte_timeout: float = 4.0          # Seconds to make QTE choice
@export var combat_duration: float = 18.0     # Seconds of combat
@export var summary_duration: float = 3.0     # Seconds to show summary
```

### Time Scale Drama
The QTE phase runs at 70% time scale for dramatic tension:
```gdscript
Engine.time_scale = 0.7  # During QTE
Engine.time_scale = 1.0  # Restored on choice
```

### Camera Shake
In `scripts/Player.gd`:
```gdscript
func trigger_camera_shake(intensity: float, duration: float) -> void
# Called automatically on damage, or manually from Main.gd
```

### SubViewport Resolution
In `scenes/Main.tscn`, find the `GameViewport` SubViewport node:
```
size = Vector2i(480, 320)  # Change for different internal resolution
```

### CRT Shader Settings
In `scenes/Main.tscn`, the SubViewportContainer material shader parameters:
```gdshader
barrel_distortion = 0.06    # 0.0 - 0.3 (lens curvature, keep low)
vignette_intensity = 0.2    # 0.0 - 1.0 (corner darkening)
scanline_intensity = 0.18   # 0.0 - 1.0 (horizontal line darkness)
scanline_count = 320.0      # Match vertical resolution
color_depth = 16.0          # 2.0 - 32.0 (posterization levels per channel)
dither_strength = 0.02      # 0.0 - 1.0 (ordered dither amount)
noise_intensity = 0.02      # 0.0 - 0.15 (film grain)
brightness = 1.0            # 0.8 - 1.2
saturation = 1.05           # 0.5 - 1.5
contrast = 1.05             # 0.8 - 1.3
```

### Palette Materials
All ship materials are in `materials/` with:
```gdscript
metallic = 0.0
roughness = 1.0
# No textures, no normal maps - just albedo_color
```

Edit colors directly in the `.tres` files:
- `mat_player_hull.tres` - Muted green `Color(0.25, 0.45, 0.3)`
- `mat_cockpit.tres` - Dark grey-blue `Color(0.15, 0.18, 0.25)`
- `mat_enemy_red.tres` - Desaturated red `Color(0.55, 0.2, 0.18)`
- `mat_enemy_yellow.tres` - Hazard yellow `Color(0.7, 0.6, 0.15)`
- `mat_neutral_grey.tres` - Generic metal `Color(0.35, 0.35, 0.38)`

### Lighting
In `scenes/Main.tscn`:
```gdscript
# DirectionalLight3D (key light)
light_energy = 0.9  # Keep modest, not washed out
shadow_enabled = false  # 1994 didn't have realtime shadows

# Environment (ambient)
ambient_light_energy = 0.4
ambient_light_color = Color(0.08, 0.08, 0.12)  # Very dark blue
glow_enabled = false
tonemap_mode = 0  # Linear
```

### Starfield
In `scripts/Starfield.gd`:
```gdscript
@export var star_count: int = 150
@export var sphere_radius: float = 80.0
@export var rotation_speed: float = 0.02  # Slow drift
```
Stars are placed on a sphere that follows the camera - they never zoom in or out, just rotate slowly for parallax.

### Player Settings
In `scripts/Player.gd`:
```gdscript
@export var move_speed: float = 8.0       # Lateral movement speed
@export var forward_speed: float = 20.0   # Constant forward speed
@export var bounds_x: float = 5.0         # Horizontal movement limit
@export var bounds_y: float = 3.0         # Vertical movement limit
@export var fire_rate: float = 0.15       # Seconds between shots
```

### Enemy Spawning
In `scripts/EnemySpawner.gd`:
```gdscript
@export var spawn_interval: float = 1.5   # Seconds between spawns
@export var max_enemies: int = 12         # Maximum concurrent enemies
@export var spawn_distance: float = 80.0  # How far ahead to spawn
```

### Enemy Behavior
In `scripts/Enemy.gd`:
```gdscript
@export var drift_speed: float = 5.0      # Enemy movement speed
@export var score_value: int = 100        # Points when destroyed
```

## Game Mechanics

- **Shield**: Starts at 100, decreases by 15 when hit by enemies
- **Score**: +100 points per enemy destroyed
- **Game Over**: When shield reaches 0, "MISSION FAILED" appears and the scene reloads after 3 seconds

## Technical Notes

- The HUD is on a separate `CanvasLayer` (layer 10) so it's NOT affected by the CRT shader, keeping text crisp
- Physics layers:
  - Layer 1: Player
  - Layer 2: Enemies
  - Layer 3: Player bullets
- All ships use simple primitive meshes (BoxMesh, PrismMesh) - no imported 3D models
- Starfield uses a spherical distribution that follows the camera, providing infinite parallax without zooming
- Materials use `metallic = 0.0` and `roughness = 1.0` for flat 1994-era shading
- No shadows, no HDR, no bloom - deliberately basic rendering

## Visual Philosophy

When in doubt between "more realistic" and "more 1994," always choose **more 1994**.

The goal is **"lovingly shitty"** - clearly low-budget, chunky, but consistent and readable. Think Gouraud shading, not PBR. Think DOS games, not Unreal Engine 5.

## Future Improvements (Not in this tech demo)

- Sound effects and music
- Multiple weapon types
- Boss enemies
- Power-ups
- Level progression
- Main menu / pause screen
- Gamepad support

---

*This is a proof-of-concept tech demo for the Salamander Wing project.*
