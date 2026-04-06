# Y2Notes 2

A cross-platform (iPad-priority) note-taking app built with Flutter & Dart, inspired by GoodNotes.

## Features (Planned)

- ✨ Magical writing effects (ink flow, neon glow, shimmer, watercolor, chalk, rainbow ink, and more)
- 🖊️ Pressure-sensitive stylus support with Apple Pencil priority
- 📑 Multi-tab workspace
- 🧷 Sticker system (GoodNotes + Procreate level)
- 🔷 Smart shape recognition with snap & align
- 🧩 Interactive widget system (timer, checklist, calculator, etc.)
- 📎 Attachments (PDF, audio, images, links)
- 😈 Magic Mode & 🧠 Study Mode
- 🎨 Beautiful GoodNotes-inspired UI/UX
- ☁️ Cloud sync

## Tech Stack

- **Framework:** Flutter (Dart)
- **State Management:** flutter_bloc
- **Navigation:** GoRouter
- **Stroke Rendering:** perfect_freehand
- **Local Storage:** Isar (planned)
- **Cloud:** Firebase (planned)

## Architecture

Clean Architecture with feature-first organization. Every system (effects, tools, widgets) is plugin-based via registries for maximum extensibility.

## Development

```bash
flutter pub get
flutter run
```

## License

MIT