# KNOWN_ISSUES

## KI-001 — V2 real-device injection/runtime not yet verified
Status: open

CI verifies compilation and Mach-O structure only. Required runtime checks:
- launch before/after scene creation
- background/foreground
- touch pass-through
- floating-button drag
- menu open/close
- rotation/resize
- multiple scenes / iPad Stage Manager

## KI-002 — Exact concept pixel match is not yet device-verified
Status: open

V2 was rebuilt from the supplied concept/real-device comparison, but no fresh V2 device screenshot has been measured yet. Do not claim pixel-match completion until a new screenshot is captured and compared.

## KI-003 — Embedded thumbnail atlas is compressed
Status: open / low risk

The 12 gallery thumbnails are embedded as a compact 4x3 JPEG atlas and cropped at runtime. This removes the V1 gradient placeholders and keeps the dylib self-contained, but the compressed 64x39 source cells can look soft when rendered larger. If this is visible on-device, replace the atlas with a higher-resolution embedded set.

## KI-004 — SF Symbol availability depends on iOS version
Status: open / compatibility

The UI uses system symbols for gear, shield, lock, camera, search, sliders, eye, walking figure and bottom tabs. `ZNSymbol` returns nil when a symbol is unavailable, so the UI should omit that icon instead of failing, but visual consistency must be checked on the minimum target OS.

## KI-005 — Host feature callbacks remain generic
Status: expected

Controls currently emit `ZNMenuValueChangedNotification`. Application-specific feature behavior must be connected separately.

## KI-006 — Host window/scene behavior still requires regression
Status: open

Some host apps may change window level, scene state or orientation after launch. The overlay architecture is unchanged from V1 and needs target-app runtime validation.
