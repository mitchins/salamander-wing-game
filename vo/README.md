# Voice-Over Directory

Place `.ogg` audio files here for character dialogue.

## Usage

Pass the filename (without path or extension) as the `audio_id` parameter:

```gdscript
Comms.say("RAZOR", "Stay sharp!", 3.0, "razor_stay_sharp")
# Will play: res://vo/razor_stay_sharp.ogg
```

## Naming Convention

Suggested format: `{character}_{description}.ogg`

Examples:
- `razor_stay_sharp.ogg`
- `vera_incoming_threat.ogg`
- `stone_hold_the_line.ogg`
