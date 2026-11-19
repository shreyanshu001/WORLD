# WORLDS — Security and privacy requirements

## Location
- Foreground permission only; no background permission or continuous tracking.
- Request location only when user chooses locate/unlock.
- Never publish current user position or store movement trails.
- Do not seed private residences, schools or sensitive facilities.
- Show approximate distance, not private creator details.
- Explain why location is requested.

## Proximity trust
GPS is inaccurate and spoofable. Server rechecks submitted coordinate/radius but a modified client can falsify location. Treat as convenience gate, never identity, safety assurance or financial proof.

## Auth and authorization
- Never ship service-role keys.
- RLS on every exposed table.
- Check ownership against authenticated identity.
- No client-controlled admin flag.
- Rate-limit creation, reports and answer attempts.
- Do not expose internal DB errors.

## Puzzle security
- Accepted answers never appear in public JSON.
- Store normalized answer hashes or equivalent server-only representation.
- Validate answers server-side and rate-limit attempts.
- Client cannot set arbitrary completion state.
- Validate block transitions server-side.

## User-generated content
Bound text, image size and block count. Validate MIME and image decoding. No scripts, HTML or executable content. Report/hide flows before public pilot. Prohibit trespass, harassment, hate, sexual exploitation and dangerous challenges.

## Storage
Owner-scoped upload paths; MIME/size restrictions; no arbitrary external image URLs; clean orphaned uploads; private drafts remain private.

## Analytics and retention
Collect product events, not continuous GPS trails. Avoid sensitive personal data. Define retention and deletion behavior before public launch.
