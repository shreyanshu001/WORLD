# Dependency selection checklist

Do not copy package versions from stale examples. Verify current stable releases against installed Flutter/Dart and Android toolchain.

| Capability | Candidate | Verification |
|---|---|---|
| State | Riverpod 3 | SDK compatibility and provider style |
| Models | Freezed | build_runner compatibility |
| JSON | json_serializable | generator compatibility |
| Routing | go_router | Flutter SDK constraints |
| Backend | supabase_flutter | auth persistence/API compatibility |
| Maps | MapLibre Flutter | maintenance, Android support, SDK constraints |
| Location | geolocator | target SDK and permission behavior |
| Media | image compression package | Android support and output size |

## Map provider gate
Read provider terms; confirm attribution, rate limits, caching, commercial use and expected pilot costs. Public OSM tile endpoint is not assumed to be a free production CDN.

## Acceptance
Commit selected versions only after Checkpoint 0. Record rejected options and rationale in this document.
