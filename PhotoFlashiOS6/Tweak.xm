#import "../PhotoFlash.h"

@interface PLCameraController (PhotoFlash)
- (void)ToggleMode:(UISwitch *)sender;
- (void)SliderDidChange:(UISlider *)sender;
@end

PLCameraSettingsGroupView *torchModeGroupView = nil;
PLCameraSettingsGroupView *torchSliderGroupView = nil;

UISwitch *torchSwitcher = nil;
UISlider *torchSlider = nil;

static void setTorchValue(PLCameraController *cameraController) {
    if ([cameraController.currentDevice isTorchAvailable]) {
        if ([cameraController _lockCurrentDeviceForConfiguration]) {
            [cameraController.currentDevice setTorchModeOnWithLevel:torchValue error:nil];
            [cameraController _unlockCurrentDeviceForConfiguration];
        }
    }
}

static void hideTools(BOOL hide, BOOL animated) {
    [UIView animateWithDuration:(animated ? kAnimInterval : 0.0) animations:^{
        torchSliderGroupView.alpha = hide ? 0.0 : 1.0;
    }];
}

CGFloat heightForCamstamp;

%hook PLCameraController

- (void)_capturedPhotoWithDictionary:(id)dictionary error:(id)error {
    %orig;
    if (torchMode && self.flashMode == 1 && self.cameraDevice == 0 && self.cameraMode == 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void) {
            if ([self.currentDevice isTorchAvailable]) {
                if ([self _lockCurrentDeviceForConfiguration]) {
                    self.currentDevice.torchMode = AVCaptureTorchModeOff;
                    [self.currentDevice setTorchModeOnWithLevel:torchValue error:nil];
                    [self _unlockCurrentDeviceForConfiguration];
                }
            }
        });
    }
}

%new
- (void)ToggleMode:(UISwitch *)sender {
    torchMode = sender.on;
    setTorchValue(self);
    writeTorchMode();
    hideTools(!torchMode, YES);
}

%new
- (void)SliderDidChange:(UISlider *)sender {
    if (torchMode || self.cameraMode != 0) {
        torchValue = sender.value;
        setTorchValue(self);
        writeTorchLevelToFile(torchValue);
    }
}

%end

%hook PLCameraView

- (void)_showSettings:(BOOL)settings sender:(id)sender {
    %orig;
    if (settings) {
        BOOL show = !(self.cameraMode + self.cameraDevice == 0);
        torchModeGroupView.hidden = show;
        torchSwitcher.hidden = show;
        hideTools(show, NO);
        if (!show)
            hideTools(!torchMode, NO);
    }
}

%end

%hook PLCameraSettingsView

- (id)initWithFrame:(CGRect)frame showGrid:(BOOL)grid showHDR:(BOOL)hdr showPano:(BOOL)pano {
    id ret = %orig;
    NSInteger count = 0;
    count += (NSInteger)(grid + hdr + pano);
    UIInterfaceOrientation orient = [UIApplication sharedApplication].statusBarOrientation;
    if (orient == UIInterfaceOrientationPortraitUpsideDown)
        count = -count;
    if (torchModeGroupView == nil) {
        torchModeGroupView = [[%c(PLCameraSettingsGroupView) alloc] initWithFrame:CGRectMake(0.0, ((56.0 * count) + heightForCamstamp), frame.size.width, 50)];
        [torchModeGroupView setType:0];
        [torchModeGroupView setTitle:@"Torch Mode"];
    }
    if (torchSliderGroupView == nil) {
        torchSliderGroupView = [[%c(PLCameraSettingsGroupView) alloc] initWithFrame:CGRectMake(0.0, ((56.0 * (1 + count)) + heightForCamstamp - 3), frame.size.width, 50)];
        [torchSliderGroupView setType:0];
        [torchSliderGroupView setTitle:@"Torch Level"];
    }
    if (torchSlider == nil) {
        torchSlider = [[UISlider alloc] init];
        torchSlider.minimumValue = 0.1;
        torchSlider.maximumValue = 1.0;
        torchSlider.value = torchValue;
        torchSlider.continuous = YES;
        torchSlider.userInteractionEnabled = YES;
        [torchSlider addTarget:self action:@selector(pt_sliderDidChange:) forControlEvents:UIControlEventValueChanged];
        [torchSlider addTarget:self action:@selector(pt_sliderTapped:) forControlEvents:UIControlEventTouchDown];
        [torchSlider addTarget:self action:@selector(pt_sliderReleased:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    }
    if (torchSwitcher == nil) {
        torchSwitcher = [[UISwitch alloc] init];
        torchSwitcher.on = torchMode;
        [torchSwitcher addTarget:self action:@selector(pt_toggleMode:) forControlEvents:UIControlEventValueChanged];
        torchSwitcher.onTintColor = [UIColor orangeColor];
    }
    torchSliderGroupView.accessorySwitch = torchSlider;
    torchModeGroupView.accessorySwitch = torchSwitcher;
    [ret addSubview:torchModeGroupView];
    [ret addSubview:torchSliderGroupView];
    hideTools(!torchMode, NO);
    return ret;
}

- (void)setFrame:(CGRect)frame {
    CGRect frame2 = frame;
    frame2.size.height += 165;
    CGRect torchModeGroupViewFrame = torchModeGroupView.frame;
    CGRect torchSliderGroupViewFrame = torchSliderGroupView.frame;
    torchModeGroupViewFrame.size.width = frame2.size.width;
    torchSliderGroupViewFrame.size.width = frame2.size.width;
    torchModeGroupView.frame = torchModeGroupViewFrame;
    torchSliderGroupView.frame = torchSliderGroupViewFrame;
    %orig(frame2);
}

- (void)dealloc {
    [torchSlider release];
    torchSlider = nil;
    [torchSliderGroupView release];
    torchSliderGroupView = nil;
    [torchSwitcher release];
    torchSwitcher = nil;
    [torchModeGroupView release];
    torchModeGroupView = nil;
    %orig;
}

%new
- (void)pt_toggleMode:(UISwitch *)sender {
    [(PLCameraController *)[%c(PLCameraController) sharedInstance] ToggleMode:sender];
}

%new
- (void)pt_sliderDidChange:(UISlider *)torchSlider {
    [(PLCameraController *)[%c(PLCameraController) sharedInstance] SliderDidChange:torchSlider];
}

%new
- (void)pt_sliderTapped:(UISlider *)slider {
    [((PLCameraController *)[%c(PLCameraController) sharedInstance]).currentDevice lockForConfiguration:nil];
}

%new
- (void)pt_sliderReleased:(UISlider *)slider {
    [((PLCameraController *)[%c(PLCameraController) sharedInstance]).currentDevice unlockForConfiguration];
}

%end

%ctor {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PostNotification, PreferencesNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
    PhotoFlashLoader();
    if (PFisOn) {
        dlopen("/System/Library/PrivateFrameworks/PhotoLibrary.framework/PhotoLibrary", RTLD_LAZY);
        heightForCamstamp = dlopen("/Library/MobileSubstrate/DynamicLibraries/Camstamp.dylib", RTLD_LAZY | RTLD_NOLOAD) ? 52.0 : 0.0;
        %init;
    }
}
