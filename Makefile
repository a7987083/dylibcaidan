ARCHS = arm64
TARGET = iphone:clang:latest:13.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = NeonModifier
NeonModifier_FILES = \
    Sources/Entry.mm \
    Sources/ZNOverlay.mm \
    Sources/ZNMemoryEngine.mm \
    Sources/ZNCompactLayoutFix.mm \
    Sources/ZNUIStabilityV032.mm \
    Sources/ZNRuntimeSafetyV032.mm \
    Sources/ZNMenuViewController.mm
NeonModifier_FRAMEWORKS = UIKit Foundation QuartzCore CoreGraphics
NeonModifier_CFLAGS = -fobjc-arc -fvisibility=hidden -Wall -Wextra
NeonModifier_CCFLAGS = -fobjc-arc -fvisibility=hidden -std=c++17 -Wall -Wextra
NeonModifier_LDFLAGS = -Wl,-install_name,@rpath/NeonModifier.dylib

include $(THEOS_MAKE_PATH)/library.mk
