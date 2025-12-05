# Salamander Wing - Rail Shooter Vignette

A 90s-style space rail shooter tech demo built in Godot 4, proving the engine can deliver a retro "Wing Commander / Terminal Velocity / Star Fox" aesthetic with:

- CRT filtering
- Cinematic rail segments with cockpit chatter
- QTE-style decision moments that **meaningfully affect gameplay**
- Short, intense dogfight windows
- Combat summary and scoring feedback
- Camera shake for impact

![Godot 4.3+](https://img.shields.io/badge/Godot-4.3+-blue)
![GDScript](https://img.shields.io/badge/Language-GDScript-green)

## Features

- **Complete Vignette Loop**: CINEMATIC → QTE → COMBAT → SUMMARY → repeat
- **Cinematic Autopilot**: Player watches the ship fly while radio chatter plays
- **QTE Decision Points**: Timed choices (EVADE vs HOLD) that alter the dogfight
- **Meaningful Consequences**: QTE choice changes enemy count, speed, and damage profile
- **Combat Windows**: ~18 seconds of hands-on dogfighting
- **Combat Summary**: End-of-window debrief showing damage taken and score gained
- **Time Scale Drama**: Slow-motion during QTE for cinematic tension
- **Camera Shake**: Impact feedback on damage
- **Retro CRT Shader**: Barrel distortion, scanlines, noise/grain, and vignette
- **Low-Resolution Rendering**: 480×320 SubViewport scaled up for authentic pixel look
- **Chunky HUD**: Shield meter, score display, targeting crosshair, chatter text, and summary panel

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
├── scenes/
│   ├── Main.tscn          # Main game scene (run this)
│   ├── Player.tscn        # Player ship scene
│   ├── Enemy.tscn         # Enemy ship scene
│   ├── Bullet.tscn        # Player projectile scene
│   └── Explosion.tscn     # Explosion effect scene
│
├── scripts/
│   ├── Main.gd            # State machine + scene controller
│   ├── Player.gd          # Player movement and firing
│   ├── Enemy.gd           # Enemy behavior
│   ├── Bullet.gd          # Projectile logic
│   ├── Explosion.gd       # Explosion lifecycle
│   ├── EnemySpawner.gd    # Enemy wave spawning
│   ├── GameController.gd  # Score, shield, game state
│   ├── QTEOverlay.gd      # QTE decision UI
│   ├── HUD.gd             # HUD display logic
│   └── Starfield.gd       # Procedural starfield background
│
├── shaders/
│   └── crt.gdshader       # CRT post-processing shader
│
└── ui/
    ├── HUD.tscn           # In-game HUD (shield, score, crosshair, chatter)
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
