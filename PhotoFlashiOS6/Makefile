ARCHS = armv7
TARGET = iphone:latest:6.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = PhotoFlashiOS6
PhotoFlashiOS6_FILES = Tweak.xm
PhotoFlashiOS6_FRAMEWORKS = AVFoundation UIKit
PhotoFlashiOS6_LIBRARIES = substrate
PhotoFlashiOS6_INSTALL_PATH = /Library/Application Support/PhotoFlash

include $(THEOS_MAKE_PATH)/library.mk
