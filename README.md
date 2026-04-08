# 🍪 Biscuits

A modern cross-platform note-taking app with magical writing effects, built with Flutter & Dart.

Designed for iPad + Huawei MatePad with first-class stylus support.

## Features

- ✨ Magical writing effects (ink flow, neon glow, shimmer, watercolor, chalk, rainbow ink, and more)
- 🖊️ Pressure-sensitive stylus support (Apple Pencil + Huawei M-Pencil)
- 📑 Multi-tab workspace with up to 8 concurrent tabs
- 🧷 Sticker system with washi tape & stamps
- 🔷 Smart shape recognition with snap & align
- 🧩 12 interactive widgets (timer, checklist, calculator, pomodoro, etc.)
- 📎 Rich media — PDF, audio, images, video
- 📐 Math graph editor with equation parser
- 🃏 Flash cards with spaced repetition (SM-2)
- 📝 PDF annotation with bookmarks & text selection
- 🔍 Document scanner with auto-crop
- ✏️ Rich text editor
- ☁️ Cloud sync (iCloud, Google Drive, OneDrive, Dropbox)
- 🎨 Warm, Apple-ish UI with light & dark themes

## Platforms

| Platform | Status |
|----------|--------|
| iOS (iPad) | ✅ Primary target |
| Android (MatePad) | ✅ Supported |
| iPhone | ✅ Supported |

## Tech Stack

- **Framework:** Flutter 3 (Dart)
- **State Management:** flutter_bloc (15 BLoCs)
- **Navigation:** GoRouter
- **Stroke Rendering:** perfect_freehand (32 drawing tools)
- **Architecture:** Clean Architecture, feature-first (22 features)
- **Local Storage:** SharedPreferences
- **PDF:** pdf + printing packages

## Architecture

Clean Architecture with feature-first organization. Every system (effects, tools, widgets) is plugin-based via registries for maximum extensibility.

```
lib/
  app/          — Routes, theme, app widget
  core/         — Canvas engine, stylus handlers, services
  features/     — 22 feature modules
  shared/       — Reusable widgets (logo, scaffold, frosted container)
```

## Development

```bash
flutter pub get
flutter run                    # Run on connected device
flutter build apk --release    # Android APK
flutter build ipa --release    # iOS IPA
flutter test                   # Run tests
```

## License

MIT