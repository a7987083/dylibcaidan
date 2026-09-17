# HANDOFF

## Repository
`a7987083/dylibcaidan`

## Active implementation branch
`feature/cyberpunk-floating-menu-v1`

## Current verified head
`db3332e65031744c6d18bbfdc1b527d5a08f96f9`

## Architecture
`Entry.mm` installs launch/active observers and starts `ZNOverlayManager`.

`ZNOverlayManager` creates a separate high-level `ZNOverlayWindow`. On iOS 13+ it attaches to a foreground `UIWindowScene`; older iOS falls back to `initWithFrame:`.

`ZNOverlayWindow` returns `nil` from `hitTest:` when the hit target is only the transparent root view, allowing host-app touches to continue outside the floating button/menu.

`ZNOverlayRootController` owns `ZNMenuViewController` and `ZNFloatingButton`.

`ZNFloatingButton` uses a pan gesture for dragging and a control event for opening/closing the menu. It intentionally does not use H5GG's repeating keep-front timer.

`ZNMenuViewController` is presentation-only. UI interactions emit `ZNMenuValueChangedNotification` with `key` and `value`. No host-specific feature implementation is wired yet.

## Build verification
GitHub Actions run `35195545064`: success.

Artifact:
- `DylibCaidan.dylib`
- Mach-O 64-bit arm64 dynamic library
- install name: `@rpath/DylibCaidan.dylib`
- SHA-256: `61a8331f97c3e7914cbea7025edda9aff3bbe4ff9e966b318e08ef694a7fa6ce`

## Reference baseline
H5GG public repository: `FloatWindow.h`, `FloatButton.h`, `makeWindow.h`. The current implementation is a rewrite, not a direct copy.

## Remaining risks
- Not yet runtime-tested in a real authorized injected target.
- Some host apps may alter window levels/scenes after launch.
- Landscape/Stage Manager/multi-scene behavior still needs device regression testing.
