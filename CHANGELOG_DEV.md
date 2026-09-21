# CHANGELOG_DEV

## 2026-09-21 — Passive Satella launcher integration

Branch: `feature/satella-passive-launch-v1`

Implemented:
- Added `SatellaPassiveCaller.h/.mm`.
- Floating-button tap now calls the verified passive Satella initializer instead of opening the local DylibCaidan menu.
- Runtime validation requires passive constructor bytes `C0 03 5F D6` at RVA `0x847C` and the verified 16-byte initializer prologue at RVA `0x888C`.
- If the target is not already loaded, only `1_passive.dylib` in the app bundle/private Frameworks path is considered, and its bytes are validated before `dlopen`.
- Updated standalone Makefile/build script to compile the caller.
- Added dedicated Actions job/artifact `DylibCaidan-SatellaLauncher-arm64`.
- Final source/CI commit: `5d5a768305a14e5b33c0bc04a01ce67706f54614`.
- Actions run: `35568200244` — success.

Validation:
- Source changed: yes.
- Exact target Mach-O offsets/prologue verified from supplied binary: yes.
- CI compiled: pending.
- Mach-O inspected: pending.
- Runtime/device verified: no.


## 2026-09-17 — Cyberpunk floating menu v1

Branch: `feature/cyberpunk-floating-menu-v1`

Implemented:
- Native UIKit/Objective-C++ dylib entry point.
- Custom overlay `UIWindow` with transparent-area touch pass-through.
- iOS 13+ foreground `UIWindowScene` selection.
- Draggable neon floating button.
- Initial cyberpunk glass/neon menu shell.
- Notification-based value-change integration point.

Validation:
- Follow-up CI run `35195545064` passed after fixing the Objective-C++ weak-reference compile error.
- Runtime/device validation was not performed for V1 before visual feedback.

## 2026-09-18 — Cyberpunk pixel-match v2

Branch: `feature/cyberpunk-pixelmatch-v2`

Reason:
- Real-device V1 screenshot showed a large visual gap from the concept image: flat panels, UIKit `UISwitch`, placeholder gradients, weak glow, missing iconography, simplified header/tabs and different proportions.

Implemented:
- Added `ZNUIComponents` with `ZNGlowPanel`, `ZNNeonSwitch`, `ZNControlRow`, `ZNSliderRow`, and image-backed `ZNPresetCell`.
- Added `ZNEmbeddedAssets` and embedded a 4x3 JPEG atlas containing 12 concept-derived preset thumbnails; runtime crops the atlas per preset, so no external resource bundle is required.
- Added `ZNMenuViewControllerV2.mm` for state, notifications, live slider values and 4x3 gallery behavior.
- Added `ZNMenuLayout.mm` with stronger cyan/purple multi-layer styling, large branding header, master toggle frame, separate left cards, camera/search controls and four independent neon bottom tabs.
- Updated `Makefile` and `Scripts/build-ios.sh` to compile the modular V2 sources instead of V1 `ZNMenuViewController.mm`.
- Preserved the existing overlay/window/drag/touch-pass-through architecture.

Important commits:
- V2 layout: `5ca756b15dcad15eb402e51b48514b9b6f93688d`
- Modular build source switch: `20d164f1ffd27d38b525580599dc3b734c2ffeff`
- Final code fix: `1f2ef8055f422fffa891ace2e86eabde506cb846`

Build verification:
- GitHub Actions run `35255740382`: success.
- Build step: success.
- Mach-O inspection: success.
- Artifact upload: success.
- Artifact: `DylibCaidan-arm64` (artifact id `10513230174`).
- Extracted dylib: Mach-O 64-bit arm64 dynamically linked shared library.
- Extracted dylib SHA-256: `a4ab2874696082b8ed5779c3d17b04e9585f17dc2b4c8432530ed24fcb0534b8`.

Validation state:
- Source changed: yes.
- CI compiled: yes.
- Mach-O inspected: yes.
- Runtime/injection verified: no.
- Real-device V2 visual regression verified: no.
