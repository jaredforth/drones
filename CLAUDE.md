# Drones

Minimal macOS app: the 12 keys on a circle of fifths (C at top, clockwise). Click a key to play its low drone (orange when playing); only one plays at a time, clicking another switches, clicking the active one stops it.

## Layout
- `Drones/Drones.swift` (app, audio, `CircleView`) and `Drones/Logo.swift` (icon art, shared with `tools/main.swift`, which renders the icon). `tools/screenshot.swift` renders the README screenshot offscreen. No Xcode project, no deps. `build.sh` compiles with `swiftc` into `build/Drones.app` (hand-written Info.plist).
- `Drone` is 12 always-available oscillators (sine + 2nd/3rd harmonics) summed through an `AVAudioSourceNode` with a `tanh` soft clip; amplitude is smoothed per sample to avoid clicks. The audio engine can sum all 12, but `Model.toggle` enforces one at a time.

## Decisions
- Arrow keys move a highlighted cursor around the circle (left/up = counterclockwise); space or return toggles that key. Implemented with an `NSEvent` local monitor (`onKeyPress` needs macOS 14).
- Pitch is octave 2 (C2 ≈ 65 Hz .. B2 ≈ 123 Hz). `A4` (440 Hz) is the tuning knob.
- Not code-signed; built locally it runs fine. Add an Xcode project only if you need signing/notarization/distribution.

## Build
`./build.sh && open build/Drones.app`
