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
| Maps | MapLibre behind an adapter; validate package and tile-provider terms before selection |
| Location | Foreground only |
| AR | Out of MVP |
| Initial launch | Small, seeded geographic pilot |

## Start here

1. Read [`docs/PRODUCT_SPEC.md`](docs/PRODUCT_SPEC.md).
2. Read [`docs/IMPLEMENTATION_PLAN.md`](docs/IMPLEMENTATION_PLAN.md).
3. Read [`docs/TECHNICAL_ARCHITECTURE.md`](docs/TECHNICAL_ARCHITECTURE.md).
4. Read [`docs/DATABASE.md`](docs/DATABASE.md).
5. Give the coding agent [`AGENTS.md`](AGENTS.md).
6. Complete Checkpoint 0 before making broad code changes.

## MVP definition

A creator publishes a World at a public location. A second user discovers it on the map, reaches its unlock radius, completes its content and has progress persisted.

That complete journey is the release gate.

## Principles

- Build the smallest complete loop, not a collection of disconnected screens.
- Use real backend data for product flows; fixtures only for tests and local previews.
- Do not expose puzzle answers to clients before validation.
- Do not track users in the background.
- Treat GPS proximity as a UX gate, not strong anti-cheat or proof of presence.
- Prefer boring, maintainable infrastructure over premature platform engineering.
