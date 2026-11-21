<div align="center">

<img src="web/icons/Icon-192.png" width="96" alt="Gymbroo logo" />

# Gymbroo

**A workout tracker for gym rats that roasts you for skipping.**

Flutter · Android · iOS · Web · 100% offline

</div>

Gymbroo logs your lifts, tells you whether you beat last time, scores your muscle balance, and sends a
7 PM nudge — or a roast — when you're behind on your weekly goals. Black and red, no accounts, no internet.

## Features

- **Goals** – first launch asks "Set your goals, broo": sessions per week for each muscle group, plus roast intensity.
- **Logging** – pick an exercise, add sets of kg × reps. Shows last time and a "beat it" target; 🏆 on a new PR (shareable).
- **Progress** – last session vs previous, this week vs last week, trend chart and history. Sessions are compared by
  estimated 1-rep max (Epley: `w × (1 + reps/30)`), so 20 kg × 10 (≈26.7) beats 15 kg × 15 (≈22.5).
  Bodyweight lifts compare reps.
- **Muscle balance score (0–100)** – sets across push / pull / legs / core over the last 4 weeks, push:pull ratio, and a roast.
- **Weekly goals** – logged workouts tick automatically; tap a box to tick manually.
- **Reminders** – a daily 7 PM notification, pre-scheduled 14 days ahead and recomputed whenever your data changes
  (train legs today and tomorrow's leg roast is cancelled). Works on Android and iOS.
- **Roasts 🍗** – three intensities (Gentle bro / Drill sergeant / No mercy), shareable as 1080×1350 cards.
- **Roast a friend** – build a roast card and send it to the group chat.

## Privacy

All data stays on the device (`shared_preferences`). The app requests no internet permission.
On Android, only the workout data is included in Google's encrypted backup / phone-to-phone transfer.

## Project layout

```
lib/main.dart            app shell, tabs, lifecycle (flushes saves on background)
lib/data.dart            models, limits, persistence, cached index, all logic
lib/roasts.dart          every roast line, by intensity
lib/notifications.dart   batched, de-duplicated reminder scheduling (Android + iOS)
lib/theme.dart           black/red palette, Panel card
lib/screens/             home, log, progress, goals, friend roast, onboarding
lib/widgets/             trend chart, share card
test/                    logic, robustness (corrupt data), stress test (3 years of data)
prototype/index.html     original single-file HTML prototype
android/  ios/  web/     platform projects
```

## Getting started

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart `^3.11.5`).

```bash
flutter pub get
flutter test
flutter run
```

### Build

```bash
# Android – arm64 covers most phones
flutter build apk --release --split-per-abi
# → build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# iOS – requires macOS + Xcode and an Apple Developer account for signing
flutter build ipa

# Web
flutter build web
```

`android/gradle.properties` is tuned for a low-memory machine (1.5 GB Gradle heap, in-process Kotlin);
close heavy apps before building.

### Release signing (Android)

Release builds read `android/key.properties` and a `.jks` keystore. Both are git-ignored — never commit them.
Back the keystore up somewhere safe: if it's lost, installed copies can never be updated.

## Status

Version `0.3.0`. Android is the primary, tested platform. The iOS project and notifications are set up
but have not yet been run on a device.
