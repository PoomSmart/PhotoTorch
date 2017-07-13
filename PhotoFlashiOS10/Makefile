ifeq ($(SIMULATOR),1)
	TARGET = simulator:clang:latest
	ARCHS = x86_64 i386
endif

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = PhotoFlashiOS10
PhotoFlashiOS10_USE_SUBSTRATE = 1
PhotoFlashiOS10_FILES = Tweak.xm ../PSPTWYPopoverController.m
PhotoFlashiOS10_FRAMEWORKS = AVFoundation CoreGraphics UIKit
PhotoFlashiOS10_LIBRARIES = substrate
PhotoFlashiOS10_INSTALL_PATH = /Library/Application Support/PhotoFlash

include $(THEOS_MAKE_PATH)/library.mk
