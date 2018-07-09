PACKAGE_VERSION = 1.6.4

include $(THEOS)/makefiles/common.mk

AGGREGATE_NAME = PhotoFlash
SUBPROJECTS = PhotoFlashiOS6 PhotoFlashiOS7 PhotoFlashiOS8 PhotoFlashiOS9 PhotoFlashiOS10 PhotoFlashLoader

include $(THEOS_MAKE_PATH)/aggregate.mk

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
