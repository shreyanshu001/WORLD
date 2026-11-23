# WORLDS

**The world is your canvas.**

WORLDS is a map-first platform for creating, discovering and experiencing digital experiences attached to real-world places.

People can create four kinds of Worlds:
- **Story** — sequential narrative with optional branches.
- **Puzzle** — clues and questions with server-validated answers.
- **Art** — visual work with supporting context.
- **Experience** — a composed sequence of supported content blocks.

The MVP is an Android-first Flutter application. It does not require AR, background location, AI generation, chat, followers or a social feed.

## Product decisions (locked)

| Area | Decision |
|---|---|
| Discovery | Map-first |
| Content | Story, Puzzle, Art, Experience |
| Creation | Any signed-in user can create |
| Initial platform | Android-first |
| Backend | Supabase + PostgreSQL + PostGIS |
| Maps | `maplibre_gl` behind `MapAdapter`; OpenFreeMap pilot tiles, with provider terms and reliability rechecked before public launch |
| Location | Foreground only |
| AR | Out of MVP |
| Initial launch | Small, seeded geographic pilot |

## Current product direction

WORLDS is moving toward shared, camera-based, location-anchored 3D experiences, with realistic/cinematic and stylized visual directions. The authoritative product and Claude Code execution brief is [`docs/PRODUCT_DIRECTION_AND_CLAUDE_HANDOFF.md`](docs/PRODUCT_DIRECTION_AND_CLAUDE_HANDOFF.md). It supersedes older statements in this README and historical MVP docs that AR is excluded. The existing map, creator, player and backend foundations remain the baseline and must be preserved.

## Start here

1. Give the coding agent [`AGENTS.md`](AGENTS.md) and [`docs/PRODUCT_DIRECTION_AND_CLAUDE_HANDOFF.md`](docs/PRODUCT_DIRECTION_AND_CLAUDE_HANDOFF.md); require it to read every document in `docs/`.
2. For product behavior, use [`docs/USER_JOURNEYS.md`](docs/USER_JOURNEYS.md).
3. For screens and interaction, use [`docs/UI_UX_SPECIFICATION.md`](docs/UI_UX_SPECIFICATION.md).
4. For measurable completion gates, use [`docs/FEATURE_ACCEPTANCE_CRITERIA.md`](docs/FEATURE_ACCEPTANCE_CRITERIA.md).
5. For architecture, schema and scope, use `TECHNICAL_ARCHITECTURE.md`, `DATABASE.md`, `PRODUCT_SPEC.md` and `IMPLEMENTATION_PLAN.md`.
6. Check [`docs/PROGRESS.md`](docs/PROGRESS.md) before starting; Checkpoints 0–3 are already implemented and merged. Do not repeat the initial audit.

## MVP definition

A creator publishes a World at a public location. A second user discovers it on the map, reaches its unlock radius, completes its content and has progress persisted.

That complete journey is the release gate.

## Development

The Flutter app lives at the repository root: `lib/`, `test/` and `android/`. Android is the only platform enabled. It was created with Flutter 3.38.3.

### Configuration

Copy `.env.example` to `.env` and fill in the Supabase project URL and its **publishable** key (`sb_publishable_...`). Both are public client values. `.env` is gitignored. Never put a secret or service-role key in it: the app refuses to start with one.

Optional keys: `MAP_STYLE_URL` and `MAP_ATTRIBUTION` switch the map provider (default: OpenFreeMap), and `EXPLORE_DEFAULT_CENTER=latitude,longitude` sets where Explore opens before the user shares a location.

### Commands

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after changing a Freezed or JSON model
flutter analyze
flutter test
flutter run --dart-define-from-file=.env
```

Without `--dart-define-from-file=.env` the app starts on a "This build is not configured" screen.

Generated files (`*.freezed.dart`, `*.g.dart`) are committed. Regenerate them whenever their source model changes.

Gradle is pinned to Java 21 by `android/gradle/gradle-daemon-jvm.properties`, so a JDK 21 must be installed (Android Studio ships one).

The app currently has its foundation, email/password accounts and profiles, the Explore map of nearby published Worlds, World details, the World creator (Checkpoint 4), on-site unlocking with the World player (Checkpoint 5), and saved Worlds, reporting, creator pages and profile counts (Checkpoint 6). Checkpoint 7 so far adds what a pilot needs from the code: four product events with no trail of where anyone went, layouts that hold at 200% text, motion whose own animations stop when the device is set to remove animations, and the operations notes. The pilot itself has not been run. Checkpoints 4, 5 and 6 are merged into `main`; Checkpoint 7 is on its branch. Their database migrations are applied to the development project. Moderation and reading the pilot's numbers are done in the Supabase dashboard (see [`supabase/README.md`](supabase/README.md)); share links are not implemented. Real-device verification gates remain open. See [`docs/PROGRESS.md`](docs/PROGRESS.md) for status.

Before testing sign-up, read the email-confirmation note in [`supabase/README.md`](supabase/README.md). Email confirmation is currently off on the development project, so new accounts are signed in at once.

## Principles

- Build the smallest complete loop, not a collection of disconnected screens.
- Use real backend data for product flows; fixtures only for tests and local previews.
- Do not expose puzzle answers to clients before validation.
- Do not track users in the background.
- Treat GPS proximity as a UX gate, not strong anti-cheat or proof of presence.
- Prefer boring, maintainable infrastructure over premature platform engineering.
