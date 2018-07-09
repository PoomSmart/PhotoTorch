ifeq ($(SIMULATOR),1)
	TARGET = simulator:clang:latest
	ARCHS = x86_64 i386
else
	TARGET = iphone:11.2:6.0
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PhotoFlash
PhotoFlash_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk
