# Salamander Wing - Tech Demo

A 90s-style space rail shooter tech demo built in Godot 4, proving the engine can deliver a retro "Wing Commander / Terminal Velocity / Star Fox" aesthetic with CRT filtering, basic combat, and a chunky HUD.

![Godot 4.3+](https://img.shields.io/badge/Godot-4.3+-blue)
![GDScript](https://img.shields.io/badge/Language-GDScript-green)

## Features

- **Retro CRT Shader**: Barrel distortion, scanlines, noise/grain, and vignette
- **Low-Resolution Rendering**: 480×320 SubViewport scaled up for authentic pixel look
- **Rail Shooter Gameplay**: Constant forward movement with bounded lateral control
- **Simple Combat**: Blaster bolts, enemy ships, explosions, score tracking
- **Chunky HUD**: Shield meter, score display, and targeting crosshair

## Requirements

- **Godot 4.3** or later (tested with Godot 4.3)
- No external addons or C# required - pure GDScript

## How to Run

1. Open Godot 4.3+
2. Import this project folder
3. Open `scenes/Main.tscn`
4. Press F5 or click Play

## Controls

| Action | Keys |
|--------|------|
| Move Up | W / Up Arrow |
| Move Down | S / Down Arrow |
| Move Left | A / Left Arrow |
| Move Right | D / Right Arrow |
| Fire | Space |

## Project Structure

```
salamander-wing-game/
├── project.godot          # Godot project file with input mappings
├── icon.svg               # Project icon
├── README.md              # This file
│
├── scenes/
│   ├── Main.tscn          # Main game scene (run this)
│   ├── Player.tscn        # Player ship scene
│   ├── Enemy.tscn         # Enemy ship scene
│   ├── Bullet.tscn        # Player projectile scene
│   └── Explosion.tscn     # Explosion effect scene
│
├── scripts/
│   ├── Main.gd            # Main scene controller
│   ├── Player.gd          # Player movement and firing
│   ├── Enemy.gd           # Enemy behavior
│   ├── Bullet.gd          # Projectile logic
│   ├── Explosion.gd       # Explosion lifecycle
│   ├── EnemySpawner.gd    # Enemy wave spawning
│   ├── GameController.gd  # Score, shield, game state
│   └── Starfield.gd       # Procedural starfield background
│
├── shaders/
│   └── crt.gdshader       # CRT post-processing shader
│
└── ui/
    └── HUD.tscn           # In-game HUD (shield, score, crosshair)
```

## Tweak Points

### SubViewport Resolution
In `scenes/Main.tscn`, find the `GameViewport` SubViewport node:
```
size = Vector2i(480, 320)  # Change for different internal resolution
```

### CRT Shader Intensity
In `scenes/Main.tscn`, find the `SubViewportContainer` material shader parameters:
```gdshader
barrel_distortion = 0.08    # 0.0 - 0.3 (lens curvature)
scanline_intensity = 0.12   # 0.0 - 1.0 (scanline visibility)
scanline_count = 320.0      # Match vertical resolution
noise_intensity = 0.025     # 0.0 - 0.2 (film grain)
vignette_intensity = 0.25   # 0.0 - 1.0 (corner darkening)
brightness = 1.05           # 0.8 - 1.2
saturation = 1.1            # 0.5 - 1.5
```

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
- All ships use simple BoxMesh primitives for authentic low-poly look
- Starfield uses procedural mesh generation for infinite scrolling

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
