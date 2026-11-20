# WORLDS — Decision log

## Accepted
- **D-001 Map-first discovery:** location is the product differentiator.
- **D-002 Four launch categories:** Story, Puzzle, Art, Experience.
- **D-003 Open creation:** any authenticated user can create/publish subject to validation, rate limits and moderation.
- **D-004 No AR in MVP:** GPS-based experiences first; prove demand before device-specific complexity.
- **D-005 Supabase/Postgres/PostGIS:** minimize solo-operator burden while supporting spatial queries.
- **D-006 Foreground location only:** privacy, battery and permission simplicity.
- **D-007 Structured blocks:** safe rendering and schema evolution.
- **D-008 Start on the installed Flutter 3.38.3 / Dart 3.10.1:** product-owner decision, 2026-11-19. This SDK is verified on the development machine. Alternatives were a per-project pin to Flutter 3.50.x (latest packages, not verified on this machine) and a global upgrade (changes other projects on the machine). Trade-off: 11 of 17 recommended packages resolve below their latest release. Revisit when a required package needs a newer SDK. Evidence: `docs/REPOSITORY_AUDIT.md`.
- **D-009 Placeholder application ID `com.example.worlds`:** product-owner decision, 2026-11-19. Google Play rejects `com.example`, so a real application ID must replace it before any release build.

The next four were adopted on the audit's recommendation when the product owner said to go ahead with Checkpoint 1 (2026-11-20). The owner did not choose them individually.

- **D-010 Gradle pinned to Java 21 per project:** `android/gradle/gradle-daemon-jvm.properties` contains `toolchainVersion=21`. It overrides the machine's user-level JDK 20 setting for this project only. Alternatives: change the machine-wide setting (could break older projects on the machine) or set `GRADLE_OPTS` in every shell (easy to forget). Requires a JDK 21 on the building machine. Audit decision D2.
- **D-011 Publishable Supabase key:** configuration uses `SUPABASE_PUBLISHABLE_KEY`, because Supabase is deprecating legacy anon and service-role keys by the end of 2026. The app refuses to start with a secret or service-role key. Audit decision D9.
- **D-012 Generated code is committed:** `*.freezed.dart` and `*.g.dart` are committed so a fresh clone builds without running `build_runner`. Audit decision D11.
- **D-013 Hand-written Riverpod providers:** `riverpod_generator`, `riverpod_annotation` and `riverpod_lint` are not used. On Flutter 3.38.3 the generator holds Riverpod at 3.1.0; without it Riverpod resolves to 3.3.2, and the slow `build_runner` step stays limited to Freezed and json_serializable. Revisit if the project moves to a newer Flutter.

Checkpoint 2 decisions:

- **D-014 Usernames chosen at sign-up:** product-owner decision, 2026-11-20. 3–20 characters of lower-case letters, digits and underscores, unique, stored lower-case. If the requested name is invalid or taken when the account is created, sign-up still succeeds with a generated `user_` name the user can change. Alternative rejected: generated names for everyone.
- **D-015 Remote Supabase project as the development database, changed through the MCP connection:** product-owner decision, 2026-11-20. Migrations are dry-run with their tests, applied from the committed file's exact contents, then renamed to the version Supabase records. The MCP connection stays write-capable by the owner's choice; ad-hoc schema changes through it remain forbidden. See `supabase/README.md`.

Checkpoint 3 decisions. The owner said "continue" without choosing, so the first four were adopted on the audit's recommendation (2026-11-20); the rest are implementation choices recorded for review.

- **D-016 Map package `maplibre_gl` 0.27.1:** wrapped behind `MapAdapter` in `lib/core/maps`; a test fails if it is imported anywhere else. Alternative deferred: the newer `maplibre` package (floating native version, much less use). Audit decision D4.
- **D-017 OpenFreeMap tiles for development and pilot:** free, commercial use allowed, no key, no SLA. Stadia Maps Starter ($20/month) remains the pre-approved fallback, switchable through `MAP_STYLE_URL` and `MAP_ATTRIBUTION`. Map tile requests go to this third party, which sees the device's IP address and the areas being viewed. Audit decision D5.
- **D-018 Title search is part of the nearby query:** `get_nearby_worlds` takes an optional `search_text` (case-insensitive, `%` and `_` literal). Resolves audit gap G2.
- **D-019 Browsing needs no account:** the nearby query is callable signed out. Whether unlocking and playing need an account is still open for Checkpoint 5 (rest of audit gap G3).
- **D-020 World text limits (proposed):** title 3–80 characters, trimmed; description at most 2,000 characters. Not specified in the documents; change by a forward migration if the product needs other limits.
- **D-021 Location is read only when the user taps "find Worlds near me":** even if permission was granted earlier. One reading with a 15-second limit; MapLibre's own location layer stays off because it tracks continuously. Before Android's permission prompt, a short dialog explains that location is used only on tap, is not tracked in the background and is never shown to others. Before that, Explore opens at `EXPLORE_DEFAULT_CENTER` if set, otherwise zoomed out. **The pilot area, and so the default centre, is undecided.**

Checkpoint 4 decisions, 2026-11-20. The owner approved Checkpoint 4 and asked for work to proceed without further questions unless genuinely blocked, so these restrictive defaults were taken and reported in the baseline; the owner has not chosen them individually. D-022 is left unused because `docs/USER_JOURNEYS.md` already reserves it for the play-account decision.

- **D-023 Content limits (proposed):** at most 30 parts per World. Text 2,000 characters; caption 200; choice prompt 300, 2–4 options of 80; question 500, hint 300, success message 300, answer 1–100 after normalisation; artwork title 80, description 2,000; ending title 80, message 1,000. Images: JPEG, PNG or WebP, at most 5 MB, at most 40 per World. At most 20 new Worlds per account per day. Enforced by the database; mirrored in `WorldRules` for quick feedback.
- **D-024 Content blocks are readable by their creator only until the player exists:** `docs/DATABASE.md` says blocks are readable whenever the parent World is. That would let anyone read a published World's whole content remotely, including story branches, which defeats the unlock step. Details show only safe fields and a part count. Public content reading is designed with the player in Checkpoint 5.
- **D-025 Which parts each category uses, and how stories branch:** Story uses text, image, choice and ending; Puzzle uses text, image, question and ending; Art uses artwork, text, image and ending; Experience uses all six. A choice may lead only to a later part, so every path moves towards an end and cannot loop. An ending finishes its branch; otherwise the experience finishes after the last part. Publishing needs at least one non-ending part, plus a question (Puzzle), an artwork (Art) or a text part (Story).
- **D-026 Puzzle answers:** one accepted answer per question. It is normalised (Unicode NFKC, lower case, whitespace collapsed, trimmed; accents still count) and stored as a bcrypt hash in `private.world_question_secrets`, which the Data API cannot reach. The creator's app sends it once with a save and only ever learns that an answer exists. Checkpoint 5 must use the same normalisation. Alternatives deferred: several accepted answers per question.
- **D-027 Draft and publish lifecycle:** drafts may be saved before they have a place. "Unpublished" is a draft that has a publish date; the database has no separate status. A published World can be edited, but each save must keep it publishable. Hidden Worlds cannot be edited, published or deleted by their creator. Deleting is a soft delete; files stay in storage until a retention policy exists.
- **D-028 Images:** a private `world-media` bucket with owner-scoped paths and signed addresses. Only the cover of a published public World is readable by others. Photos come from Android's system photo picker, which needs no storage or media permission, are resized to 2,048 px at quality 85, and are checked by their first bytes. `image_picker` alone is used; a separate compression package was not needed. The server checks the stored object's owner, path, declared type and size, but does not decode images. No thumbnails yet (image transforms need a paid plan).
- **D-029 Unlisted Worlds are not offered yet:** gap G1 remains open. The creator cannot choose "unlisted", and details open only published public Worlds (plus the creator's own). Decide with share links in Checkpoint 6.
- **D-030 Backend stays on Supabase Cloud:** product-owner decision, 2026-11-20, after asking to deploy "on AWS". Supabase Cloud already runs on AWS; self-hosting or rebuilding on native AWS services was not chosen. The project's region should be checked against the pilot area before launch.

## Pending; require evidence and rationale
- Pilot area, and the Explore default centre that goes with it (D-021).
- Whether unlisted Worlds open by direct link (gap G1, D-029).
- Whether unlocking and playing a World needs an account (audit gap G3, Checkpoint 5).
- Dependency versions for later checkpoints (Flutter/Dart settled by D-008; Checkpoint 1 packages recorded in `docs/DEPENDENCY_DECISIONS.md`).
- Final application ID (placeholder in use, see D-009).
- Supabase region/configuration.
- Image transform/thumbnail strategy.
- Email confirmation and custom SMTP for the pilot (see `supabase/README.md`).

Do not silently resolve pending decisions. Record evidence, alternatives and trade-offs.
