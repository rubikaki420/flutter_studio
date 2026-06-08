# flutter_studio — Termux Project

Flutter-based IDE for Android (com.vault.fide) with a Termux fork backend at `/data/data/com.vault.fide/files/usr/`.

## Root Cause
`dart:io` Process calls in Flutter don't inherit the Termux fork PATH — they get Android system PATH instead, causing "file not found" for commands like `apt`, `dart`, `flutter`, `node`, `npm`, `python`, `pip`.

## Fix Applied
- **`lib/core/termux_env.dart`** — centralized `TermuxEnv` class with full PATH (includes Android SDK tools, platform-tools, build-tools, Flutter bin, CMake) plus JAVA_HOME, ANDROID_HOME, PREFIX, HOME, TMPDIR. Provides `TermuxEnv.start()` / `TermuxEnv.run()` wrappers.
- All bare `Process.start`/`Process.run` calls replaced with `TermuxEnv.start`/`TermuxEnv.run` across:
  - `lib/core/language/language.dart` (PreInstallChecker)
  - All 8 language installers (c, cpp, dart, flutter, html, js, ts, python)
  - Project creation progress dialogs (dart, flutter)
  - LSP manager passes `TermuxEnv.environment` to `LspStdioConfig`

## Constraints
- **DO NOT modify** `android/termux/` — it's the Termux fork native source.
- The Termux fork CLI works standalone; only Flutter `dart:io` Process calls are affected.
- No runtime install scripts needed — the app has its own apt repo for dependencies.

## Build
- GitHub workflow: `test` branch → APK build
- `flutter build apk --debug` via CI
- Flutter/Dart not available in this dev environment

## Git
- `test` branch is used for CI verification before merging to main.
