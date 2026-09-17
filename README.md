# dylibcaidan

Native iOS floating-menu dylib prototype implemented with UIKit/Objective-C++.

## Current UI

- Cyberpunk neon skin based on the selected concept: cyan/magenta glow, dark glass panels, left tweak controls, right preset grid, bottom tabs.
- Draggable floating button.
- Tap floating button to open/close the menu.
- Transparent areas pass touches back to the host app.
- Uses an independent high-level `UIWindow` and `UIWindowScene` on iOS 13+.
- No polling timer is used to keep the overlay in front.
- Toggle/slider/tab changes are emitted through `ZNMenuValueChangedNotification` for later integration with application-specific logic.

## Build

### GitHub Actions
Push to `main` or `feature/**`. The workflow builds an arm64 iOS dylib on a macOS runner and uploads `DylibCaidan-arm64`.

### Local Xcode toolchain
```bash
chmod +x Scripts/build-ios.sh
Scripts/build-ios.sh
```

### Theos
```bash
make clean package
```

Target binary: `DylibCaidan.dylib`.

## H5GG reference
The overlay architecture was designed after reviewing the MIT-licensed H5GG project, especially `FloatWindow.h`, `FloatButton.h`, and `makeWindow.h`. This implementation is rewritten for this project and avoids H5GG's timer-based keep-front behavior.
