ifeq ($(SIMULATOR),1)
	TARGET = simulator:clang:latest
	ARCHS = x86_64 i386
else
	TARGET = iphone:latest:8.0
endif

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = PhotoFlashiOS8
PhotoFlashiOS8_USE_SUBSTRATE = 1
PhotoFlashiOS8_FILES = Tweak.xm ../PSPTWYPopoverController.m
PhotoFlashiOS8_FRAMEWORKS = AVFoundation CoreGraphics UIKit
PhotoFlashiOS8_LIBRARIES = substrate
PhotoFlashiOS8_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries/PhotoFlash

include $(THEOS_MAKE_PATH)/library.mk
