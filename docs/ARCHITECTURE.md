# Biscuits Architecture Guide

> Living document — updated alongside the codebase.

---

## Layers

```
lib/
├── app/          # App shell: routing, theme, entry point
├── core/         # Cross-cutting: DI, services, utils, engine
├── features/     # Feature modules (clean architecture)
└── shared/       # Shared UI widgets and models
```

### `app/`

| File | Purpose |
|------|---------|
| `main.dart` | Bootstrap, zone error handling, DI init |
| `app.dart` | Root `MaterialApp` widget |
| `routes.dart` | GoRouter configuration with error page |
| `route_names.dart` | Type-safe route path constants |
| `error_page.dart` | Fallback page for unknown routes |
| `theme/` | Design tokens, colours, motion |

### `core/`

| Directory | Purpose |
|-----------|---------|
| `di/` | `ServiceLocator` + `initDependencies()` |
| `services/` | `SettingsService` facade, `AppLogger`, `StorageService` |
| `services/settings/` | Focused sub-services (theme, effects, stylus, …) |
| `engine/` | Low-level rendering, stylus, haptics |
| `utils/` | `Result<T>`, math helpers, device capability |
| `constants/` | App-wide constants |
| `extensions/` | Dart extension methods |
| `io/` | Platform I/O stubs |

### `features/<name>/`

Each feature follows **clean architecture**:

```
features/<name>/
├── domain/
│   ├── entities/       # Immutable data classes
│   ├── models/         # Value objects, configs
│   └── repositories/   # Abstract repository interfaces
├── data/               # Concrete repository implementations
├── presentation/
│   ├── bloc/           # BLoC + events + state
│   ├── pages/          # Full-screen widgets
│   └── widgets/        # Feature-specific widgets
└── engine/             # (optional) Feature-specific engines
```

### `shared/`

Reusable UI components (`AppleButton`, `FrostedContainer`,
`ResponsiveLayout`, etc.) and shared models.

---

## Dependency Injection

A lightweight **service locator** (`lib/core/di/service_locator.dart`)
provides singleton, lazy-singleton, and factory registrations without
an external package.

```dart
// Register
final sl = ServiceLocator.instance;
sl.registerSingleton<MyService>(MyService());

// Retrieve
final service = sl<MyService>();
```

All registrations happen in `initDependencies()`
(`lib/core/di/dependencies.dart`), called once in `main()`.

### What is registered

| Registration | Type | Scope |
|-------------|------|-------|
| `SharedPreferences` | singleton | app lifetime |
| `StorageService` | singleton | app lifetime |
| `SettingsService` | singleton | facade |
| `ThemeSettings` | singleton | sub-service |
| `EffectsSettings` | singleton | sub-service |
| `StylusSettings` | singleton | sub-service |
| `RecognitionSettings` | singleton | sub-service |
| `CanvasSettings` | singleton | sub-service |
| `BackupSettings` | singleton | sub-service |
| `ToolSettings` | singleton | sub-service |
| `DocumentRepository` | lazy singleton | first use |
| `LibraryRepository` | lazy singleton | first use |
| `TemplateRepository` | lazy singleton | first use |
| `FlashCardRepository` | lazy singleton | first use |

---

## Error Handling

### `Result<T>` (`lib/core/utils/result.dart`)

A sealed union for operation outcomes:

```dart
final result = await repository.loadNotebook(id);
result.when(
  success: (notebook) => emit(state.copyWith(notebook: notebook)),
  failure: (error) => emit(state.copyWith(error: error.message)),
);
```

- `Result.success(value)` / `Result.failure(AppError(…))`
- `.map()`, `.flatMap()`, `.valueOrNull`, `.errorOrNull`
- `AppError` carries a machine-readable `code` and human-readable
  `message`.

### Zone guard

`main()` wraps the app in `runZonedGuarded` + `FlutterError.onError`
so uncaught errors are logged via `AppLogger` instead of crashing
silently.

---

## Logging

`AppLogger` (`lib/core/services/app_logger.dart`) is a pluggable
singleton:

```dart
AppLogger.instance.info('Loaded 42 items', tag: 'Library');
AppLogger.instance.error('Write failed', error: e, tag: 'Storage');
```

The default `DebugLogger` writes to `debugPrint` only in debug mode.
Swap `AppLogger.instance` for a Crashlytics adapter in production.

---

## Settings Architecture

`SettingsService` is a **backward-compatible facade** that delegates
to seven focused sub-services:

| Sub-service | Responsibility |
|-------------|----------------|
| `ThemeSettings` | Dark mode |
| `EffectsSettings` | Writing + interaction effects |
| `StylusSettings` | Pressure, tilt, gestures |
| `RecognitionSettings` | Handwriting language, confidence |
| `CanvasSettings` | Spacing, margin, page template |
| `BackupSettings` | Auto-save, export format |
| `ToolSettings` | Default sizes, haptics, presets |

Existing code can continue using `settingsService.setDarkMode(…)`.
New code should inject the specific sub-service it needs.

---

## Repository Interfaces

Abstract contracts live in `domain/repositories/`:

| Interface | Implemented by |
|-----------|---------------|
| `IDocumentRepository` | `DocumentRepository` |
| `ILibraryRepository` | `LibraryRepository` |
| `ITemplateRepository` | `TemplateRepository` |
| `IFlashCardRepository` | `FlashCardRepository` |

These enable:
- Swapping local ↔ cloud backends transparently.
- Easy mocking in BLoC tests with `mocktail`.

---

## Routing

- **Type-safe paths**: `AppRoutes.notebook(id)` instead of `'/notebook/$id'`.
- **Error page**: Unknown routes display `ErrorPage` with a back button.
- **GoRouter** handles all navigation declaratively.

---

## Conventions

| Topic | Convention |
|-------|-----------|
| UI strings | British English (`favourite`, `colour`) |
| Code identifiers | American English (`isFavorite`, `colorLabel`) |
| State management | BLoC for feature state; `ValueNotifier` for settings |
| Design system | Apple-style tokens (`AppleCurves`, `AppleDurations`, …) |
| Min tap target | 44 pt |
| Spacing grid | 8 pt |
| Tests | `bloc_test` + `mocktail`; run `flutter test` |
