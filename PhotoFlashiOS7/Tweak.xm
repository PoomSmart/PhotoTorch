#import "../PhotoFlash.h"
#import "../PSPTWYPopoverController.h"

@interface CAMTopBar (PhotoTorch)
- (BOOL)pt_shouldHideYellowDot;
@end

@interface PLCameraView (PhotoTorch)
- (BOOL)pt_topBarShouldHideYellowDot:(id)arg1;
- (BOOL)pt_shouldHideYellowDotForMode:(NSInteger)mode;
- (BOOL)pt__shouldEnableYellowDot;
@end

#define isStillImageBackCamera(view) ((view.cameraDevice == 0) && [view _isStillImageMode:view.cameraMode])
#define isVideoMode(controller) ((controller.cameraDevice == 0) && [(PLCameraController *)[NSClassFromString(@"PLCameraController") sharedInstance] _isVideoMode:controller.cameraMode])

BOOL prevent;

static void setTorchValue(PLCameraController *cameraController) {
    if ([cameraController.currentDevice isTorchAvailable]) {
        if ([cameraController _lockCurrentDeviceForConfiguration]) {
            BOOL isVideoMode1 = isVideoMode(cameraController);
            if (torchMode || isVideoMode1)
                [cameraController.currentDevice setTorchModeOnWithLevel:torchValue error:nil];
            if (!torchMode && !isVideoMode1)
                cameraController.currentDevice.torchMode = AVCaptureTorchModeOff;
            [cameraController _unlockCurrentDeviceForConfiguration];
        }
    }
}

@interface PhotoTorchTableDataSource : NSObject <UITableViewDataSource, UITableViewDelegate> {
    PLCameraController *cameraController;
    PLCameraView *cameraView;
}
- (id)initWithCameraController:(PLCameraController *)newCameraController;
@property(retain, nonatomic) PLCameraController *cameraController;
@property(retain, nonatomic) PLCameraView *cameraView;
@property(retain, nonatomic) UISlider *slider;
@end

CAMShutterButton *btn;

UIViewController *vc;
UITableView *tb;
PSPTWYPopoverController *popover;

@implementation PhotoTorchTableDataSource
@synthesize cameraController;
@synthesize cameraView;

- (id)initWithCameraController:(PLCameraController *)newCameraController {
    if (self == [super init]) {
        self.cameraController = newCameraController;
        self.cameraView = newCameraController.delegate;
    }
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? (isStillImageBackCamera(self.cameraView) ? 2 : 1) : 0;
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
    prevent = YES;
    setTorchValue(self.cameraController);
    prevent = NO;
    writeTorchMode();
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
    self.slider.value = isStillImageBackCamera(self.cameraView) ? torchValue : self.cameraController.currentDevice.torchLevel;
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
            cell.backgroundColor = self.cameraView._topBar._backgroundView.backgroundColor;
            cell.contentView.backgroundColor = [UIColor clearColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        switch (indexPath.row) {
            case 0:
            {
                UISlider *torchSlider1 = [self torchSlider];
                [cell.contentView addSubview:torchSlider1];
                if (!isStillImageBackCamera(self.cameraView))
                    torchSlider1.enabled = (self.cameraController.currentDevice.torchLevel > 0.0);
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
                toggle.onTintColor = [UIColor systemOrangeColor];
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

static void listTapped(PLCameraView *self, UIButton *button) {
    vc = [UIViewController new];
    ds = [[PhotoTorchTableDataSource alloc] initWithCameraController:(PLCameraController *)[NSClassFromString(@"PLCameraController") sharedInstance]];
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
    [popover presentPopoverFromRect:button.bounds inView:button permittedArrowDirections:PSPTWYPopoverArrowDirectionAny animated:YES];
}

static void createListButton(CAMTopBar *topBar) {
    btn = [%c(CAMShutterButton) smallShutterButton];
    btn.transform = CGAffineTransformMakeScale(0.55f, 0.55f);
    MSHookIvar<UIView *>(btn, "__innerView").backgroundColor = [UIColor systemYellowColor];
    MSHookIvar<UIView *>(btn, "__outerView").hidden = YES;
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    btn.userInteractionEnabled = YES;
    [btn addTarget:[(PLCameraController *)[%c(PLCameraController) sharedInstance] delegate] action:@selector(pt_listTapped:) forControlEvents:UIControlEventTouchUpInside];
    [topBar insertSubview:btn aboveSubview:([topBar respondsToSelector:@selector(_backgroundView)] ? topBar._backgroundView : topBar)];
    NSLayoutConstraint *sideInset = nil;
    if (rightBtn)
        sideInset = [NSLayoutConstraint constraintWithItem:btn attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationLessThanOrEqual toItem:topBar attribute:NSLayoutAttributeRight multiplier:1.0 constant:-64.0f];
    else
        sideInset = [NSLayoutConstraint constraintWithItem:btn attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationLessThanOrEqual toItem:topBar attribute:NSLayoutAttributeLeft multiplier:1.0 constant:81.0f];
    NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:btn attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:topBar attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0f];
    [topBar addConstraints:@[sideInset, centerY]];
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

%group iOS71

%hook PLCameraView

- (void)_updateFlashModeIfNecessary {
    if (prevent)
        return;
    %orig;
}

%end

%end

%hook CAMTopBar

%new
- (BOOL)pt_shouldHideYellowDot {
    if ([self _isFlashButtonExpanded])
        return YES;
    return [self _shouldHideFlashButton];
}

- (void)_updateHiddenViewsForButtonExpansionAnimated:(BOOL)animated {
    %orig;
    [btn pl_setHidden:[self pt_shouldHideYellowDot] animated:animated];
}

%end

%hook PLCameraView

%new
- (void)pt_listTapped: (UIButton *)button {
    listTapped(self, button);
}

- (void)_createDefaultControlsIfNecessary {
    %orig;
    createListButton(self._topBar);
}

- (void)_rotateCameraControlsAndInterface {
    %orig;
    cleanup();
}

%new
- (BOOL)pt_topBarShouldHideYellowDot: (id)arg1 {
    return [self pt_shouldHideYellowDotForMode:self.cameraMode];
}

%new
- (BOOL)pt_shouldHideYellowDotForMode: (NSInteger)mode {
    return [self _shouldHideFlashButtonForMode:mode] || self.cameraDevice != 0;
}

%new
- (BOOL)pt__shouldEnableYellowDot {
    return [self _shouldEnableFlashButton] && self.cameraDevice == 0;
}

- (void)_updateEnabledControlsWithReason:(id)arg1 forceLog:(BOOL)log {
    %orig;
    btn.enabled = [self pt__shouldEnableYellowDot];
}

- (void)_showControlsForChangeToMode:(NSInteger)mode animated:(BOOL)animated {
    %orig;
    [btn pl_setHidden:[self pt_shouldHideYellowDotForMode:mode] animated:animated];
}

- (void)_hideControlsForChangeToMode:(NSInteger)mode animated:(BOOL)animated {
    %orig;
    [btn pl_setHidden:[self pt_shouldHideYellowDotForMode:mode] animated:animated];
}

// Record 'n' Torch compatibility
- (void)_showControlsForCapturingVideoAnimated:(BOOL)animated {
    %orig;
    [btn pl_setHidden:[self pt_shouldHideYellowDotForMode:self.cameraMode] animated:animated];
}

- (void)_hideControlsForCapturingVideoAnimated:(BOOL)animated {
    %orig;
    [btn pl_setHidden:[self pt_shouldHideYellowDotForMode:self.cameraMode] animated:animated];
}

- (void)cameraControllerPreviewDidStart:(id)arg1 {
    %orig;
    setTorchValue((PLCameraController *)[%c(PLCameraController) sharedInstance]);
}

%end

%hook PLCameraController

- (void)_didTakePhoto {
    %orig;
    if (torchMode && self.flashMode == 1 && isStillImageBackCamera(self.delegate) && !self.performingTimedCapture) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
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

%end

%ctor {
    if (IN_SPRINGBOARD)
        return;
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PostNotification, PreferencesNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
    PhotoFlashLoader();
    if (PFisOn) {
        openCamera7();
        %init;
        if (isiOS71) {
            %init(iOS71);
        }
    }
}
