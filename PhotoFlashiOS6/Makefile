ARCHS = armv7
TARGET = iphone:7.1:6.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = PhotoFlashiOS6
PhotoFlashiOS6_FILES = Tweak.xm
PhotoFlashiOS6_FRAMEWORKS = AVFoundation UIKit
PhotoFlashiOS6_LIBRARIES = substrate
PhotoFlashiOS6_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries/PhotoFlash

include $(THEOS_MAKE_PATH)/library.mk
