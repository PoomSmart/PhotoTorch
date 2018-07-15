TARGET = iphone:latest:7.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = PhotoFlashiOS7
PhotoFlashiOS7_FILES = Tweak.xm ../PSPTWYPopoverController.m
PhotoFlashiOS7_FRAMEWORKS = AVFoundation CoreGraphics UIKit
PhotoFlashiOS7_LIBRARIES = substrate
PhotoFlashiOS7_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries/PhotoFlash

include $(THEOS_MAKE_PATH)/library.mk
