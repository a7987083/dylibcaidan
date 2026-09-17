# HANDOFF

## Repository
`a7987083/dylibcaidan`

## Active implementation branch
`feature/cyberpunk-floating-menu-v1`

## Architecture
`Entry.mm` installs launch/active observers and starts `ZNOverlayManager`.

`ZNOverlayManager` creates a separate high-level `ZNOverlayWindow`. On iOS 13+ it attaches to a foreground `UIWindowScene`; older iOS falls back to `initWithFrame:`.

`ZNOverlayWindow` returns `nil` from `hitTest:` when the hit target is only the transparent root view, allowing host-app touches to continue outside the floating button/menu.

`ZNOverlayRootController` owns `ZNMenuViewController` and `ZNFloatingButton`.

`ZNFloatingButton` uses a pan gesture for dragging and a control event for opening/closing the menu. It intentionally does not use H5GG's repeating keep-front timer.

`ZNMenuViewController` is presentation-only. UI interactions emit `ZNMenuValueChangedNotification` with `key` and `value`. No host-specific feature implementation is wired yet.

## Reference baseline
H5GG public repository: `FloatWindow.h`, `FloatButton.h`, `makeWindow.h`.
The current implementation is a rewrite, not a direct copy.

## Risks
- Dylib has not yet been runtime-tested in a real injected target.
- Some host apps may alter window levels/scenes after launch.
- Landscape/Stage Manager/multi-scene behavior still needs device regression testing.
