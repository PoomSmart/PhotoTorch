#define UNRESTRICTED_AVAILABILITY
#define KILL_PROCESS
#import "../PS.h"

NSString *PREF_PATH = @ "/var/mobile/Library/Preferences/com.PS.PhotoFlash.plist";
CFStringRef PreferencesNotification = CFSTR("com.PS.PhotoFlash.settingschanged");

NSString *kPFEnabledKey = @ "PFEnabled";
NSString *kPFTorchKey = @ "enableTorch";
NSString *kPFTorchVal = @ "torchValue";
NSString *kRightBtnKey = @ "rightBtn";

CGFloat kAnimInterval = 0.25;

BOOL PFisOn;
BOOL torchMode;
BOOL rightBtn;

float torchValue;

static void PhotoFlashLoader() {
    NSMutableDictionary *prefs = [NSMutableDictionary dictionary];
    [prefs addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:PREF_PATH]];
    if (prefs.count == 0) {
        [prefs setObject: @ (torchMode)forKey:kPFTorchKey];
        [prefs writeToFile: PREF_PATH atomically: NO];
    }
    PFisOn = prefs[kPFEnabledKey] ? [prefs[kPFEnabledKey] boolValue] : YES;
    torchValue = prefs[kPFTorchVal] ? [prefs[kPFTorchVal] floatValue] : 1.0;
    if (torchValue == 1.0)
        torchValue = AVCaptureMaxAvailableTorchLevel;
    torchMode = prefs[kPFTorchKey] ? [prefs[kPFTorchKey] boolValue] : YES;
    rightBtn = [prefs[kRightBtnKey] boolValue];
}

static void writeTorchLevelToFile(float torchLevel) {
    NSMutableDictionary *prefs = [NSMutableDictionary dictionary];
    [prefs addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:PREF_PATH]];
    [prefs setObject: @ (torchLevel)forKey: kPFTorchVal];
    [prefs writeToFile: PREF_PATH atomically: NO];
}

static void writeTorchMode() {
    NSMutableDictionary *prefs = [NSMutableDictionary dictionary];
    [prefs addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:PREF_PATH]];
    [prefs setObject: @ (torchMode)forKey: kPFTorchKey];
    [prefs writeToFile: PREF_PATH atomically: NO];
}

static void PostNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    killProcess("Camera");
    PhotoFlashLoader();
}

#define flashSupportedForDevice(device) (device != 1)
#define _isStillImageCamera(mode, device) (flashSupportedForDevice(device) && (mode == 0 || mode == 4))
#define _isVideoMode(mode, device) (flashSupportedForDevice(device) && (mode == 1 || mode == 2 || mode == 6))
