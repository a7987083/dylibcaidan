# CHANGELOG_DEV

## 2026-09-17 — Cyberpunk floating menu v1

Branch: `feature/cyberpunk-floating-menu-v1`

Implemented:
- Native UIKit/Objective-C++ dylib entry point.
- Custom overlay `UIWindow` with transparent-area touch pass-through.
- iOS 13+ foreground `UIWindowScene` selection.
- Draggable neon floating button.
- Cyberpunk glass/neon menu skin.
- Left-side toggles/sliders, right-side preset grid, bottom tabs.
- Notification-based value-change integration point.
- Theos Makefile and Xcode CLI build script.
- macOS GitHub Actions build workflow.
- Project handoff/state/known-issues documentation.

Build history:
- Initial CI run failed in `Sources/ZNOverlay.mm` at `__weak typeof(self)` under the Objective-C++ C++17 build.
- Root cause fixed by replacing GNU `typeof` with the explicit Objective-C type `__weak ZNOverlayRootController *`.
- Follow-up CI run `35195545064` passed.
- Produced `DylibCaidan.dylib`, Mach-O 64-bit ARM64 dynamic library.
- Extracted dylib SHA-256: `61a8331f97c3e7914cbea7025edda9aff3bbe4ff9e966b318e08ef694a7fa6ce`.

Validation state:
- Source review: completed.
- Git repository write: completed.
- CI compilation: passed.
- Mach-O type/dependencies inspection: passed.
- Runtime/device validation: not performed.
