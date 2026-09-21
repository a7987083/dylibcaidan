ARCHS = arm64
TARGET = iphone:clang:latest:13.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = DylibCaidan
DylibCaidan_FILES = Sources/Entry.mm Sources/SatellaPassiveCaller.mm Sources/ZNOverlay.mm Sources/ZNEmbeddedAssets.mm Sources/ZNUIComponents.mm Sources/ZNMenuViewControllerV2.mm Sources/ZNMenuLayout.mm
DylibCaidan_FRAMEWORKS = UIKit Foundation QuartzCore CoreGraphics
DylibCaidan_CFLAGS = -fobjc-arc -fvisibility=hidden -Wall -Wextra
DylibCaidan_CCFLAGS = -fobjc-arc -fvisibility=hidden -std=c++17 -Wall -Wextra
DylibCaidan_LDFLAGS = -Wl,-install_name,@rpath/DylibCaidan.dylib

include $(THEOS_MAKE_PATH)/library.mk
