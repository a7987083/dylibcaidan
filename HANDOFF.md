# HANDOFF

## Repository
`a7987083/dylibcaidan`

## Active implementation branch
`feature/cyberpunk-pixelmatch-v2`

## Stable baseline
V1/docs baseline: `818bce37dd8a84980f4d831f3c5cce11b13fde1b`

## V2 code baseline
`1f2ef8055f422fffa891ace2e86eabde506cb846`

This is the code commit whose GitHub Actions run `35255740382` built and inspected successfully. Later commits on the branch may be documentation-only.

## Architecture
`Entry.mm` starts `ZNOverlayManager` after launch/activation.

`ZNOverlay.mm` owns the high-level overlay `UIWindow`, foreground `UIWindowScene` selection, transparent hit-test pass-through and draggable floating button. The overlay implementation keeps the rewritten H5GG-inspired architecture and does not use H5GG's repeating keep-front timer.

V2 UI is modular:
- `ZNUIComponents.h/.mm`: glow panels, custom neon switch, control rows, slider rows, preset cells.
- `ZNEmbeddedAssets.h/.mm`: self-contained base64 JPEG atlas and runtime crop lookup for 12 concept-derived preset thumbnails.
- `ZNMenuViewControllerV2.mm`: menu state, notifications, slider values, gallery data source/layout sizing.
- `ZNMenuLayout.mm`: complete V2 hierarchy and Auto Layout geometry.
- `ZNMenuPrivate.h`: shared private declarations across the V2 implementation units.

`Makefile` and `Scripts/build-ios.sh` compile the V2 modules; the old `ZNMenuViewController.mm` remains in the repository only as the V1 reference and is not in the V2 compile list.

UI interaction integration remains generic: controls emit `ZNMenuValueChangedNotification` with `key` and `value`.

## V2 visual changes from real-device feedback
- Replaced system `UISwitch` with `ZNNeonSwitch`.
- Replaced gradient placeholder presets with embedded concept-derived thumbnails.
- Added stronger cyan/purple glow, layered borders and dark glass gradients.
- Added SF Symbol iconography to sections, control rows and tabs.
- Added numeric slider values (`1.0x`, `75°`) and live updates.
- Split left-side content into GLOBAL TWEAKS and PLAYER CONTROL cards.
- Rebuilt top branding/master toggle and four separate bottom neon buttons.
- Increased menu sizing toward the concept proportions while keeping safe-area bounds.

## Build verification
GitHub Actions run `35255740382`: success.

Artifact:
- name: `DylibCaidan-arm64`
- artifact id: `10513230174`
- extracted type: Mach-O 64-bit arm64 dynamically linked shared library
- dylib SHA-256: `a4ab2874696082b8ed5779c3d17b04e9585f17dc2b4c8432530ed24fcb0534b8`

## Next task
Inject the V2 artifact into the authorized test target and capture a new landscape screenshot. Compare it directly against the supplied concept before any additional visual tuning. Do not infer V2 pixel-match quality from CI; CI proves compilation/Mach-O validity only.

## Remaining risks
- No physical-device V2 runtime test yet.
- Exact visual/pixel match is not yet measured.
- Embedded atlas cells are intentionally compressed and may need higher-resolution assets if the device render exposes blur.
- SF Symbol availability can differ by iOS version; missing symbols should degrade by omitting the image rather than crashing.
- Host apps can still change window levels/scenes after startup; this remains a runtime regression item.
