# WORLDS — Implementation progress

**Phase:** Pre-implementation  
**Current checkpoint:** 0 — Repository reconnaissance (audit delivered, awaiting approval)  
**Product direction:** Approved  
**Documentation handoff:** Published to GitHub  
**App implementation:** Not started

| Checkpoint | Status | Evidence |
|---|---|---|
| Documentation handoff | Complete | README, AGENTS.md and 12 supporting files committed to main |
| 0. Repository audit | Audit delivered — awaiting product-owner approval | `docs/REPOSITORY_AUDIT.md`, 2026-11-19 |
| 1. Project foundation | Not started | — |
| 2. Backend and identity | Not started | — |
| 3. Explore map | Not started | — |
| 4. World details and creator | Not started | — |
| 5. Experience player | Not started | — |
| 6. Saved/profile/moderation | Not started | — |
| 7. Beta and pilot | Not started | — |

## Current blockers

- Checkpoint 0 needs product-owner approval before Checkpoint 1 starts.
- Twelve decisions (D1–D12) are open in `docs/REPOSITORY_AUDIT.md`. Six gate Checkpoint 1: D1 (Flutter SDK strategy), D2 (Gradle JDK), D3 (application ID), D9, D11 and D12.
- A Supabase project exists but has not been inspected: the Supabase MCP sign-in must be completed by the owner from a regular terminal.
- Map package and tile provider are recommended in the audit but not yet approved.

## Checkpoint 0 record

- **Date:** 2026-11-19
- **Commit audited:** `d31f872` on `main`. Checkpoint 0 changes are not yet committed.
- **Summary:** The project is greenfield: the repository holds documentation only, and the product owner confirmed that no Flutter source exists elsewhere. The audit covers the installed toolchain, a dependency compatibility spike run outside the repository, map package and tile-provider review, Supabase platform facts, and a consistency pass over the documents.
- **Files changed:** `docs/REPOSITORY_AUDIT.md` (new), `docs/PROGRESS.md`, `docs/DEPENDENCY_DECISIONS.md`, `.mcp.json` (new, Supabase MCP server config added at the owner's request). No application source and no migrations.
- **Tests and results:** The repository has no Dart code, so there was nothing to format, analyze or test in it (`dart format` reported "Formatted no files"). In the throwaway spike on Flutter 3.38.3: dependency resolution passed, `build_runner` passed, `flutter analyze` reported no issues, `flutter test` passed 2 of 2, and `flutter build apk --debug` failed on the machine's default JDK 20 and passed on JDK 21.
- **Manual device verification:** None. A physical Android 16 device was detected but nothing was installed on it; real-device map verification is the Checkpoint 3 gate.
- **Known issues:**
  - Installed Flutter 3.38.3 is one year behind current stable 3.50.0; 11 of 17 recommended packages resolve below their latest release.
  - A user-level Gradle setting forces JDK 20, which breaks the MapLibre plugin build. A project-level fix is verified and planned for Checkpoint 1.
  - The Supabase project's region, plan, PostGIS state, auth settings and existing schema are not verified.
  - No Supabase CLI, Docker or `psql` is installed. Whether the Supabase CLI runs through `npx` on this machine is not verified.
  - Android SDK licenses are not all accepted.
  - Four gaps between the specification documents (G1–G4 in the audit) need product decisions.
  - `.mcp.json` enables write-capable Supabase MCP tools; the audit recommends `read_only=true` until Checkpoint 2.
- **Approval status:** Pending.

## Update protocol
For each checkpoint record date, commit SHA, summary, tests and results, manual device verification, known issues and approval status. Never mark a checkpoint complete without evidence.
