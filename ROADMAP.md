# ROADMAP

## Phase 1 — Floating UI shell
Status: implemented in `feature/cyberpunk-floating-menu-v1`

- [x] Independent overlay window
- [x] iOS 13+ `UIWindowScene` selection
- [x] Transparent hit-test pass-through
- [x] Draggable floating button
- [x] Open/close menu animation
- [x] Cyberpunk neon skin
- [x] Toggle and slider widgets
- [x] Preset `UICollectionView`
- [x] Bottom navigation tabs
- [x] GitHub Actions arm64 dylib build definition

## Phase 2 — Integration API
Next task:
- Add typed callback/delegate bindings for host features.
- Persist menu position and UI values.
- Add optional configuration JSON for feature definitions.

## Phase 3 — Runtime validation
- Inject built dylib into an authorized test app.
- Verify touch pass-through, rotation, scene changes, suspend/resume and memory behavior on device.
