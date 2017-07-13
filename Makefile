DEBUG = 0
PACKAGE_VERSION = 1.6.2

ifeq ($(SIMULATOR),1)
	TARGET = simulator:clang:latest
	ARCHS = x86_64 i386
endif

include $(THEOS)/makefiles/common.mk

AGGREGATE_NAME = PhotoFlash
SUBPROJECTS = PhotoFlashiOS6 PhotoFlashiOS7 PhotoFlashiOS8 PhotoFlashiOS9 PhotoFlashiOS10

include $(THEOS_MAKE_PATH)/aggregate.mk

TWEAK_NAME = PhotoFlash
PhotoFlash_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp -R PhotoFlash $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)find $(THEOS_STAGING_DIR) -name .DS_Store | xargs rm -rf$(ECHO_END)

SIM_TARGET = PhotoFlashiOS10
all::
ifeq ($(SIMULATOR),1)
	@rm -f /opt/simject/$(SIM_TARGET).dylib
	@cp -v $(THEOS_OBJ_DIR)/$(SIM_TARGET).dylib /opt/simject
	@cp -v $(PWD)/$(AGGREGATE_NAME).plist /opt/simject/$(SIM_TARGET).plist
endif
