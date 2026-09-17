# ROADMAP

## Phase 1 — Floating UI shell
Status: compiled and CI-verified on `feature/cyberpunk-floating-menu-v1`

- [x] Independent overlay window
- [x] iOS 13+ `UIWindowScene` selection
- [x] Transparent hit-test pass-through
- [x] Draggable floating button
- [x] Open/close menu animation
- [x] Cyberpunk neon skin
- [x] Toggle and slider widgets
- [x] Preset `UICollectionView`
- [x] Bottom navigation tabs
- [x] GitHub Actions arm64 dylib build
- [x] Mach-O/linked-framework inspection in CI

## Phase 2 — Runtime validation
Next task:
- Inject the CI-built dylib into an authorized test app.
- Verify touch pass-through, rotation/resize, scene changes and suspend/resume.
- Record device/iOS version and runtime logs.

## Phase 3 — Integration API
- Add typed callback/delegate bindings for host features.
- Persist menu position and UI values.
- Add optional configuration JSON for feature definitions.
