# KNOWN_ISSUES

## KI-001 — Real-device injection not yet verified
Status: open

The dylib source and build configuration exist, but no authorized physical-device runtime test has been performed yet.

Validation needed:
- startup before/after scene creation
- background/foreground
- touch pass-through
- floating button dragging
- menu rotation/resize
- multiple scenes / iPad Stage Manager

## KI-002 — Placeholder preset thumbnails
Status: expected

The preset grid uses generated gradient cards instead of bundled image assets. This keeps the dylib self-contained. Replace with project-owned assets later if the exact concept-art thumbnails are required.

## KI-003 — Host feature callbacks are intentionally generic
Status: expected

Controls currently post `ZNMenuValueChangedNotification`. Real application feature handlers must be connected separately.
