# Drones

Minimal Android app: a 3×4 grid of the 12 chromatic keys. Tap a key to play a low drone in that key; tap it again to stop; tap another to switch.

## Layout
- Single-module Gradle project; the root project *is* the app (no `app/` dir).
- All code is in `src/main/kotlin/dev/jaredforth/drones/MainActivity.kt`: UI built in code (no XML layouts), plain `android.app.Activity`, no AndroidX or other deps.
- `Drone` is a thread streaming 16-bit mono PCM at 48 kHz to an `AudioTrack`: sine plus 2nd/3rd harmonics, amplitude smoothed per sample to avoid clicks.

## Decisions
- Pitch is octave 2 (C2 ≈ 65 Hz to B2 ≈ 123 Hz). Harmonics are added because phone speakers barely reproduce the fundamental.
- `A4` constant (440 Hz) is the tuning knob.
- No foreground service: the drone keeps playing in the background until the activity is destroyed, but Android may kill it. Add a media foreground service if that becomes a problem.

## Build
- AGP 9.4.1 (built-in Kotlin, no Kotlin plugin), compileSdk/targetSdk 37, minSdk 26.
- `./gradlew assembleDebug` → `build/outputs/apk/debug/drones-debug.apk`
- Install: `~/Library/Android/sdk/platform-tools/adb install -r build/outputs/apk/debug/drones-debug.apk`
- Emulator: `~/Library/Android/sdk/emulator/emulator -avd Medium_Phone_API_37.0`. Its media volume defaults to 5/15 (-33 dB), which makes the drone inaudible on laptop speakers; raise it with `adb shell cmd media_session volume --stream 3 --set 15`. To confirm the track is playing: `adb shell dumpsys media.audio_flinger` (look for the app's uid, `A` state, gain and underruns).
- Button tints are set explicitly (`IDLE`/`ACTIVE`). Setting `backgroundTintList = null` turns Material buttons white instead of restoring the theme color.
- `local.properties` (gitignored) points `sdk.dir` at `~/Library/Android/sdk`.
