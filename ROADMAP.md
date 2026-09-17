# ROADMAP

## Phase 1 — Floating UI shell
Status: completed / CI-verified

- [x] Independent overlay `UIWindow`
- [x] iOS 13+ foreground `UIWindowScene`
- [x] Transparent hit-test pass-through
- [x] Draggable floating button
- [x] Menu open/close animation
- [x] ARM64 dylib build and Mach-O inspection

## Phase 2 — Cyberpunk Pixel-Match V2
Status: implemented / CI-verified on `feature/cyberpunk-pixelmatch-v2`

- [x] Replace flat V1 menu with layered cyan/purple neon shell
- [x] Custom neon toggle instead of `UISwitch`
- [x] Icon + title + live-value slider rows
- [x] Split GLOBAL TWEAKS / PLAYER CONTROL cards
- [x] Rebuild top branding / master toggle / bottom neon tabs
- [x] Embed 12 concept-derived preset thumbnails into the dylib
- [x] Build modular V2 source set
- [x] GitHub Actions build + Mach-O inspection + artifact upload

## Phase 3 — Real-device visual regression
Next task:
- Inject the V2 artifact built from code commit `1f2ef8055f422fffa891ace2e86eabde506cb846` into the authorized test app.
- Capture a fresh landscape screenshot at the same orientation/scale as the concept.
- Compare panel geometry, spacing, typography, glow, icons, sliders, toggles and thumbnails against the reference.
- Apply only measured V2 tuning changes after the screenshot comparison.

## Phase 4 — Runtime regression / integration API
- Verify touch pass-through, floating-button drag, rotation/resize, scene changes and suspend/resume.
- Add typed host callbacks/delegates as needed.
- Persist menu position and values.
- Optionally add JSON-driven feature definitions.
