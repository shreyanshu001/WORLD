# WORLDS — Technical architecture

> **2026-11-23:** This is the architecture of the implemented non-AR MVP and still governs it. The next phase adds a native Android AR module behind a small typed Flutter boundary (handoff §6, D-043); nothing of it is built yet. Contracts that AR will have to change (camera permission, one-shot location, image-only assets, unversioned published content) are listed in `docs/PHASE_0_AUDIT.md` §4.

## Principles
- Flutter feature-first, layered architecture.
- Server owns authorization, publish validation and puzzle answers.
- PostGIS owns nearby filtering.
- Map/location SDKs are replaceable adapters.
- Structured, versioned content only.
- Avoid microservices and custom backend for MVP.

## Recommended stack (verify compatibility at Checkpoint 0)
| Concern | Choice | Notes |
|---|---|---|
| Mobile | Flutter/Dart | Android-first |
| State | Riverpod 3 | SDK compatibility first |
| Models | Freezed + json_serializable | Generated immutable models |
| Navigation | go_router | Named routes/auth redirects |
| Backend | Supabase | Auth, Postgres, Storage, RPC |
| Spatial DB | PostgreSQL + PostGIS | Nearby search |
| Maps | MapLibre Flutter candidate | Package and Android compatibility spike |
| Tiles | Provider selected after terms review | Attribution, caching, rate and cost |
| Location | Geolocator candidate | Foreground only |
| Media | Supabase Storage | Compression and constraints |
| Tests | flutter_test, integration_test | Unit/widget/device |

Do not pin versions until installed SDK and current package releases are checked.

## Suggested structure
```
lib/
  app/{app.dart,router/,theme/,config/}
  core/{errors/,location/,maps/,network/,widgets/,utils/}
  features/
    auth/{data,domain,application,presentation}/
    explore/{data,domain,application,presentation}/
    worlds/{data,domain,application,presentation}/
    world_player/{data,domain,application,presentation}/
    world_creation/{data,domain,application,presentation}/
    saved/
    profile/
    moderation/
  shared/{models/,components/}
supabase/{migrations/,functions/}
docs/
```

## Dependency direction
Presentation → Application → Domain. Data implements domain repository interfaces. Domain must not import Flutter widgets, Supabase SDK, map SDK or Geolocator.

## Core contracts
- `WorldRepository`: nearby, by ID, create/update draft, publish/unpublish, creator Worlds.
- `LocationService`: permission status, request foreground permission, current position; stream only while visible and explicitly needed.
- `MapAdapter`: initialize, camera movement, marker operations, dispose.
- `WorldProgressRepository`: get progress, start, save transition, submit answer, complete.

Use feature-scoped Riverpod providers/notifiers. Keep map camera gestures out of backend World state; avoid a giant global notifier.

## Backend responsibilities
Supabase Auth, Postgres/PostGIS, Storage and SQL RPC. Edge Functions only where SQL is insufficient. No separate Node/Express service in MVP. Migrations are source of truth; no undocumented dashboard-only schema.

## Geographic discovery
Store `geography(Point,4326)`; construct point longitude first, latitude second. Use GIST index, `ST_DWithin` candidate filtering and `ST_Distance` ordering. Bound result count and return preview fields only. Debounce viewport/search updates; never fetch every World and calculate distance in Dart.

## Proximity trust
Client requests foreground location. Server rechecks submitted coordinate sample against World point/radius. This is not anti-spoofing: modified clients can falsify GPS. Do not describe it as proof of presence. QR/NFC/device attestation are later decisions.

## Media
Owner-scoped upload staging. Validate MIME, size, dimensions, owner and World association. Publish only after server verifies asset ownership. Compress and thumbnail. Clean orphaned uploads.

## Error model
Map backend failures to typed states: unauthenticated, permission denied, location unavailable, stale/low accuracy, not found, unpublished, locked, invalid content, upload failed, rate limited and offline. Never show raw SQL/PostgREST errors.

## Observability and performance
Record failures without sensitive coordinates/content. No movement trails. Bound map results, debounce camera/search, cache safe previews briefly, paginate lists, compress images and test mid-range Android devices.
