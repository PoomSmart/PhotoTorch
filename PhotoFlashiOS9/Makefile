ifeq ($(SIMULATOR),1)
	TARGET = simulator:clang:latest
	ARCHS = x86_64 i386
else
	TARGET = iphone:latest:9.0
endif

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = PhotoFlashiOS9
PhotoFlashiOS9_USE_SUBSTRATE = 1
PhotoFlashiOS9_FILES = Tweak.xm ../PSPTWYPopoverController.m
PhotoFlashiOS9_FRAMEWORKS = AVFoundation CoreGraphics UIKit
PhotoFlashiOS9_LIBRARIES = substrate
PhotoFlashiOS9_INSTALL_PATH = /Library/Application Support/PhotoFlash

include $(THEOS_MAKE_PATH)/library.mk
