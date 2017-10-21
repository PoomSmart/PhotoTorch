#import "../PhotoFlash.h"
#import "../PSPTWYPopoverController.h"
#import <UIKit/UIColor+Private.h>

@interface CAMTopBar (PhotoTorch)
- (BOOL)pt_shouldHideYellowDot;
@end

@interface CAMBottomBar (PhotoTorch)
- (BOOL)pt_shouldHideYellowDot;
@end

@interface CAMViewfinderViewController (PhotoTorch)
- (BOOL)pt_topBarShouldHideYellowDot:(id)arg1;
- (BOOL)pt_shouldHideYellowDotForGraphConfiguration:(CAMCaptureGraphConfiguration *)configuration;
- (BOOL)pt__shouldEnableYellowDot;
@end

CAMViewfinderViewController *vf;

#define isStillImageCamera(controller) (_isStillImageCamera(controller._currentMode, controller._currentDevice))
#define isVideoMode(controller) (_isVideoMode(controller._currentMode, controller._currentDevice))
#define __currentMode (vf._currentMode)
#define __currentDevice (vf._currentDevice)

static void setTorchValue(CAMViewfinderViewController *cameraController){
    AVCaptureDevice *cameraDevice = cameraController._captureController._captureEngine.cameraDevice;
    if ([cameraDevice isTorchAvailable]) {
        if ([cameraDevice lockForConfiguration:nil]) {
            BOOL isVideoMode1 = isVideoMode(cameraController);
            if (torchMode || isVideoMode1)
                [cameraDevice setTorchModeOnWithLevel:torchValue error:nil];
            if (!torchMode && !isVideoMode1)
                cameraDevice.torchMode = AVCaptureTorchModeOff;
            [cameraDevice unlockForConfiguration];
        }
    }
}

@interface PhotoTorchTableDataSource : NSObject <UITableViewDataSource, UITableViewDelegate> {
    CAMViewfinderViewController *cameraController;
    CAMViewfinderView *cameraView;
}
- (id)initWithCameraController:(CAMViewfinderViewController *)newCameraController;
@property(retain, nonatomic) CAMViewfinderViewController *cameraController;
@property(retain, nonatomic) CAMViewfinderView *cameraView;
@property(retain, nonatomic) UISlider *slider;
@end

static CUShutterButton *btn = nil;
CGFloat btnSize;
CGFloat topBarHeight;

UIViewController *vc;
UITableView *tb;
PSPTWYPopoverController *popover;

@implementation PhotoTorchTableDataSource
@synthesize cameraController;
@synthesize cameraView;

- (id)initWithCameraController:(CAMViewfinderViewController *)newCameraController {
    if (self == [super init]) {
        self.cameraController = newCameraController;
        self.cameraView = (CAMViewfinderView *)(newCameraController.view);
    }
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? (isStillImageCamera(self.cameraController) ? 2 : 1) : 0;
}

- (void)sliderValueChanged:(UISlider *)sender {
    torchValue = sender.value;
    if (torchMode || isVideoMode(self.cameraController))
        setTorchValue(self.cameraController);
    if (!isVideoMode(self.cameraController))
        writeTorchLevelToFile(torchValue);
}

- (void)toggleSwitch:(UISwitch *)sender {
    torchMode = sender.on;
    setTorchValue(self.cameraController);
    writeTorchMode();
}

- (NSInteger)torchMode {
    return [self.cameraController respondsToSelector:@selector(torchMode)] ? self.cameraController.torchMode : self.cameraController._torchMode;
}

- (void)updateSliderAvailability {
    if (!isStillImageCamera(self.cameraController))
        self.slider.enabled = (self.cameraController._captureController._captureEngine.cameraDevice.torchLevel > 0.0) && self.torchMode != 0;
}

- (UISlider *)torchSlider {
    if (self.slider == nil) {
        self.slider = [UISlider new];
        self.slider.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.slider.minimumValue = 0.1f;
        self.slider.maximumValue = 1.0f;
        self.slider.tintColor = [UIColor systemYellowColor];
        [self.slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
    self.slider.value = isStillImageCamera(self.cameraController) ? torchValue : self.cameraController._captureController._captureEngine.cameraDevice.torchLevel;
    return self.slider;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if (indexPath.section == 0) {
        static NSString *ident = [NSString stringWithFormat:@"PTControl%lu", (long)indexPath.row];
        cell = [tableView dequeueReusableCellWithIdentifier:ident];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ident];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.backgroundColor = self.cameraController._topBar._backgroundView.backgroundColor;
            cell.contentView.backgroundColor = [UIColor clearColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.layoutMargins = UIEdgeInsetsZero;
            cell.preservesSuperviewLayoutMargins = NO;
        }
        switch (indexPath.row) {
            case 0:
            {
                UISlider *torchSlider1 = [self torchSlider];
                [cell.contentView addSubview:torchSlider1];
                [self updateSliderAvailability];
                torchSlider1.bounds = CGRectMake(0.0f, 0.0f, cell.contentView.bounds.size.width - 30.0f, torchSlider1.bounds.size.height);
                torchSlider1.center = CGPointMake(CGRectGetMidX(cell.contentView.bounds), CGRectGetMidY(cell.contentView.bounds));
                torchSlider1.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
                break;
            }
            case 1:
            {
                cell.textLabel.text = @"Torch mode";
                cell.textLabel.textColor = [UIColor whiteColor];
                UISwitch *toggle = [[UISwitch alloc] initWithFrame:CGRectZero];
                toggle.onTintColor = [UIColor orangeColor];
                [toggle addTarget:self action:@selector(toggleSwitch:) forControlEvents:UIControlEventValueChanged];
                toggle.on = torchMode;
                cell.accessoryView = toggle;
                break;
            }
        }
    }
    return cell;
}

@end

PhotoTorchTableDataSource *ds;

static void listTapped(CAMViewfinderViewController *self, UIButton *button){
    vc = [UIViewController new];
    ds = [[PhotoTorchTableDataSource alloc] initWithCameraController:self];
    tb = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tb.dataSource = ds;
    tb.delegate = ds;
    tb.backgroundColor = [UIColor clearColor];
    tb.separatorInset = UIEdgeInsetsZero;
    tb.scrollEnabled = NO;
    tb.allowsMultipleSelection = NO;
    tb.alpha = self._topBar.alpha;
    [tb reloadData];
    CGFloat height = CGRectGetMaxY([tb rectForSection:[tb numberOfSections] - 1]);
    vc.view = tb;
    popover = [[PSPTWYPopoverController alloc] initWithContentViewController:vc];
    [popover beginThemeUpdates];
    popover.theme.dimsBackgroundViewsTintColor = NO;
    popover.theme.fillTopColor = self._topBar._backgroundView.backgroundColor;
    popover.theme.fillBottomColor = self._topBar._backgroundView.backgroundColor;
    popover.theme.innerStrokeColor = [UIColor whiteColor];
    [popover endThemeUpdates];
    popover.wantsDefaultContentAppearance = NO;
    popover.popoverContentSize = CGSizeMake(220.0f, height);
    [popover presentPopoverFromRect:button.bounds inView:button permittedArrowDirections:IS_IPAD ? PSPTWYPopoverArrowDirectionRight : PSPTWYPopoverArrowDirectionAny animated:YES];
}

static void positionBtn(CAMTopBar *topBar){
    if (btn) {
        if (IS_IPAD) {
            CGFloat topBarWidth = topBar.frame.size.width;
            btn.frame = CGRectMake(topBarWidth > 0 ? (topBarWidth / 2 - btnSize / 2) : 51 - btnSize / 2, topBar.flipButton.frame.origin.y + btnSize * 3 + 7, btnSize, btnSize);
        } else {
            CGFloat originY = 20 - btnSize / 2;
            if (!rightBtn)
                btn.frame = CGRectMake(topBar.flashButton.frame.origin.x + topBar.flashButton.frame.size.width - 3, originY, btnSize, btnSize);
            else
                btn.frame = CGRectMake(topBar.flipButton.frame.origin.x - 5 - btnSize, originY, btnSize, btnSize);
        }
    }
}

static void createListButton(CAMTopBar *topBar){
    btn = (CUShutterButton *)[%c(CUShutterButton) tinyShutterButtonWithLayoutStyle : 1];
    btnSize = [btn intrinsicContentSize].width;
    MSHookIvar<UIView *>(btn, "__innerView").backgroundColor = UIColor.systemYellowColor;
    MSHookIvar<UIView *>(btn, "__outerView").layer.borderWidth = 3.0f;
    btn.userInteractionEnabled = YES;
    [btn addTarget:vf action:@selector(pt_listTapped:) forControlEvents:UIControlEventTouchUpInside];
    if ([topBar respondsToSelector:@selector(_backgroundView)])
        [topBar insertSubview:btn aboveSubview:topBar._backgroundView];
    else if ([topBar respondsToSelector:@selector(backgroundView)])
        [topBar insertSubview:btn aboveSubview:((CAMBottomBar *)topBar).backgroundView];
    positionBtn(topBar);
}

static void cleanup() {
    if (popover) {
        [popover dismissPopoverAnimated:YES];
        [popover release];
        popover = nil;
    }
    if (vc) {
        [vc release];
        vc = nil;
    }
    if (tb) {
        [tb release];
        tb = nil;
    }
}

%hook CAMTopBar

%new
- (BOOL)pt_shouldHideYellowDot {
    if (self._expandedMenuButton == self.flashButton)
        return YES;
    #if TARGET_OS_SIMULATOR
    return NO;
    #else
    return [self shouldHideFlashButtonForGraphConfiguration:[vf _currentGraphConfiguration]] || !flashSupportedForDevice(__currentDevice);
    #endif
}

- (void)_updateControlVisibilityAnimated:(BOOL)animated {
    %orig;
    [btn cam_setHidden:[self pt_shouldHideYellowDot] animated:animated];
}

- (void)layoutSubviews {
    %orig;
    positionBtn(self);
}

%end

%hook CAMBottomBar

- (void)layoutSubviews {
    %orig;
    if (IS_IPAD)
        positionBtn((CAMTopBar *)self);
}

%new
- (BOOL)pt_shouldHideYellowDot {
    if (self._expandedMenuButton == self.flashButton)
        return YES;
    #if TARGET_OS_SIMULATOR
    return NO;
    #else
    return [vf _shouldHideFlashButtonForGraphConfiguration:[vf _currentGraphConfiguration]] || !flashSupportedForDevice(__currentDevice);
    #endif
}

- (void)_updateControlVisibilityAnimated:(BOOL)animated {
    %orig;
    if (IS_IPAD)
        [btn cam_setHidden:[self pt_shouldHideYellowDot] animated:animated];
}

%end

%hook CAMViewfinderViewController

- (id)initWithCaptureController: (CUCaptureController *)arg1 captureConfiguration: (id)arg2 conflictingControlConfiguration: (id)arg3 locationController: (id)arg4 motionController: (id)arg5 timelapseController: (id)arg6 keepAliveController: (id)arg7 remoteShutterController: (id)arg8 powerController: (id)arg9 cameraRollController: (id)arg10 usingEmulationMode: (NSInteger)arg11 initialLayoutStyle: (NSInteger)arg12 {
    self = %orig;
    vf = self;
    return self;
}

- (void)loadView {
    %orig;
    createListButton(IS_IPAD ? (CAMTopBar *)self._bottomBar : self._topBar);
}

- (void)_previewDidStartRunning:(id)arg1 {
    %orig;
    positionBtn(self._topBar);
}

%new
- (void)pt_listTapped: (UIButton *)button
{
    listTapped(self, button);
}

- (void)_rotateTopBarAndControlsToOrientation:(UIInterfaceOrientation)orientation shouldAnimate:(BOOL)animated {
    %orig;
    cleanup();
    /*if ([self _shouldApplyTopBarRotationForMode:self._currentMode device:self._currentDevice])
            [btn cam_rotateWithInterfaceOrientation:orientation animated:animated];*/
}

- (void)stillImageRequestDidCompleteStillImageCapture:(id)arg1 withResponse:(id)arg2 error:(id)arg3 {
    %orig;
    if (torchMode && self.flashMode == 1 && isStillImageCamera(self) && ![self._captureController isCapturingBurst]) {
        AVCaptureDevice *cameraDevice = self._captureController._captureEngine.cameraDevice;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
            if ([cameraDevice isTorchAvailable]) {
                if ([cameraDevice lockForConfiguration:nil]) {
                    cameraDevice.torchMode = AVCaptureTorchModeOff;
                    [cameraDevice setTorchModeOnWithLevel:torchValue error:nil];
                    [cameraDevice unlockForConfiguration];
                }
            }
        });
    }
}

%new
- (BOOL)pt_topBarShouldHideYellowDot: (id)arg1 {
    #if TARGET_OS_SIMULATOR
    return NO;
    #else
    return [self pt_shouldHideYellowDotForGraphConfiguration:[self _currentGraphConfiguration]];
    #endif
}

%new
- (BOOL)pt_shouldHideYellowDotForGraphConfiguration: (CAMCaptureGraphConfiguration *)configuration {
    #if TARGET_OS_SIMULATOR
    return NO;
    #else
    return [self _shouldHideFlashButtonForGraphConfiguration:configuration] || !flashSupportedForDevice(configuration.device);
    #endif
}

%new
- (BOOL)pt__shouldEnableYellowDot {
    #if TARGET_OS_SIMULATOR
    return YES;
    #else
    return [self _shouldEnableFlashButton] && flashSupportedForDevice(self._currentDevice);
    #endif
}

- (void)_updateEnabledControlsWithReason:(id)arg1 forceLog:(BOOL)log {
    %orig;
    btn.enabled = [self pt__shouldEnableYellowDot];
}

- (void)_showControlsForGraphConfiguration:(CAMCaptureGraphConfiguration *)configuration animated:(BOOL)animated {
    %orig;
    //positionBtn();
    [btn cam_setHidden:[self pt_shouldHideYellowDotForGraphConfiguration:configuration] animated:animated];
}

- (void)_hideControlsForGraphConfiguration:(CAMCaptureGraphConfiguration *)configuration animated:(BOOL)animated {
    %orig;
    [btn cam_setHidden:[self pt_shouldHideYellowDotForGraphConfiguration:configuration] animated:animated];
}

- (void)_changeToGraphConfiguration:(CAMCaptureGraphConfiguration *)to fromGraphConfiguration:(CAMCaptureGraphConfiguration *)from {
    %orig;
    if (!_isVideoMode(to.mode, to.device))
        setTorchValue(self);
}

- (void)_startCapturingVideoWithRequest:(id)arg1 {
    %orig;
    [ds updateSliderAvailability];
}

- (void)_updateTorchMode {
    %orig;
    if (!isVideoMode(self))
        setTorchValue(self);
}

- (void)_updateTorchModeOnControllerIfNecessaryForMode:(NSInteger)mode {
    %orig;
    if (!isVideoMode(self))
        setTorchValue(self);
}

%end

%ctor {
    if (IN_SPRINGBOARD)
        return;
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PostNotification, PreferencesNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
    PhotoFlashLoader();
    if (PFisOn) {
        openCamera10();
        %init;
    }
}
