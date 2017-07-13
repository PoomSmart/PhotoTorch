/*
 Version 0.2.2
 
 WYPopoverController is available under the MIT license.
 
 Copyright © 2013 Nicolas CHENG
 
 Permission is hereby granted, free of charge, to any person obtaining a copy 
 of this software and associated documentation files (the "Software"), to deal 
 in the Software without restriction, including without limitation the rights 
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
 copies of the Software, and to permit persons to whom the Software is 
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included 
 in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
 INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
 PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION 
 OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
 SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "../PS.h"

@protocol PSPTWYPopoverControllerDelegate;
@class PSPTWYPopoverTheme;

#ifndef WY_POPOVER_DEFAULT_ANIMATION_DURATION
    #define WY_POPOVER_DEFAULT_ANIMATION_DURATION    .25f
#endif

#ifndef WY_POPOVER_MIN_SIZE
    #define WY_POPOVER_MIN_SIZE                      CGSizeMake(240, 160)
#endif

typedef NS_OPTIONS(NSUInteger, PSPTWYPopoverArrowDirection) {
    PSPTWYPopoverArrowDirectionUp = 1UL << 0,
    PSPTWYPopoverArrowDirectionDown = 1UL << 1,
    PSPTWYPopoverArrowDirectionLeft = 1UL << 2,
    PSPTWYPopoverArrowDirectionRight = 1UL << 3,
    PSPTWYPopoverArrowDirectionNone = 1UL << 4,
    PSPTWYPopoverArrowDirectionAny = PSPTWYPopoverArrowDirectionUp | PSPTWYPopoverArrowDirectionDown | PSPTWYPopoverArrowDirectionLeft | PSPTWYPopoverArrowDirectionRight,
    PSPTWYPopoverArrowDirectionUnknown = NSUIntegerMax
};

typedef NS_OPTIONS(NSUInteger, PSPTWYPopoverAnimationOptions) {
    PSPTWYPopoverAnimationOptionFade = 1UL << 0,            // default
    PSPTWYPopoverAnimationOptionScale = 1UL << 1,
    PSPTWYPopoverAnimationOptionFadeWithScale = PSPTWYPopoverAnimationOptionFade | PSPTWYPopoverAnimationOptionScale
};

////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface PSPTWYPopoverBackgroundView : UIView

// UI_APPEARANCE_SELECTOR doesn't support BOOLs on iOS 7,
// so these two need to be NSUInteger instead
@property (nonatomic, assign) NSUInteger usesRoundedArrow                   UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) NSUInteger dimsBackgroundViewsTintColor       UI_APPEARANCE_SELECTOR;

@property (nonatomic, strong) UIColor *tintColor                            UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *fillTopColor                         UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *fillBottomColor                      UI_APPEARANCE_SELECTOR;

@property (nonatomic, strong) UIColor *glossShadowColor                     UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) CGSize glossShadowOffset                      UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) NSUInteger glossShadowBlurRadius              UI_APPEARANCE_SELECTOR;

@property (nonatomic, assign) NSUInteger borderWidth                        UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) NSUInteger arrowBase                          UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) NSUInteger arrowHeight                        UI_APPEARANCE_SELECTOR;

@property (nonatomic, strong) UIColor *outerShadowColor                     UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *outerStrokeColor                     UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) NSUInteger outerShadowBlurRadius              UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) CGSize outerShadowOffset                      UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) NSUInteger outerCornerRadius                  UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) NSUInteger minOuterCornerRadius               UI_APPEARANCE_SELECTOR;

@property (nonatomic, strong) UIColor *innerShadowColor                     UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *innerStrokeColor                     UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) NSUInteger innerShadowBlurRadius              UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) CGSize innerShadowOffset                      UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) NSUInteger innerCornerRadius                  UI_APPEARANCE_SELECTOR;

@property (nonatomic, assign) UIEdgeInsets viewContentInsets                UI_APPEARANCE_SELECTOR;

@property (nonatomic, strong) UIColor *overlayColor                         UI_APPEARANCE_SELECTOR;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface PSPTWYPopoverController : NSObject <UIAppearanceContainer>

@property (nonatomic, assign) id <PSPTWYPopoverControllerDelegate> delegate;

@property (nonatomic, assign) BOOL                              dismissOnTap;
@property (nonatomic, copy) NSArray                            *passthroughViews;
@property (nonatomic, assign) BOOL                              dismissOnPassthroughViewTap;
@property (nonatomic, assign) BOOL                              wantsDefaultContentAppearance;
@property (nonatomic, assign) UIEdgeInsets                      popoverLayoutMargins;
@property (nonatomic, readonly, getter=isPopoverVisible) BOOL   popoverVisible;
@property (nonatomic, strong, readonly) UIViewController       *contentViewController;
@property (nonatomic, assign) CGSize                            popoverContentSize;
@property (nonatomic, assign) float                             animationDuration;
@property (nonatomic, assign) BOOL                              implicitAnimationsDisabled;

@property (nonatomic, strong) PSPTWYPopoverTheme                   *theme;

@property (nonatomic, copy) void (^dismissCompletionBlock)(PSPTWYPopoverController *dimissedController);

+ (void)setDefaultTheme:(PSPTWYPopoverTheme *)theme;
+ (PSPTWYPopoverTheme *)defaultTheme;

// initialization

- (id)initWithContentViewController:(UIViewController *)viewController;

// theme

- (void)beginThemeUpdates;
- (void)endThemeUpdates;

// Present popover from classic views methods

- (void)presentPopoverFromRect:(CGRect)rect
                        inView:(UIView *)view
      permittedArrowDirections:(PSPTWYPopoverArrowDirection)arrowDirections
                      animated:(BOOL)animated;

- (void)presentPopoverFromRect:(CGRect)rect
                        inView:(UIView *)view
      permittedArrowDirections:(PSPTWYPopoverArrowDirection)arrowDirections
                      animated:(BOOL)animated
                    completion:(void (^)(void))completion;

- (void)presentPopoverFromRect:(CGRect)rect
                        inView:(UIView *)view
      permittedArrowDirections:(PSPTWYPopoverArrowDirection)arrowDirections
                      animated:(BOOL)animated
                       options:(PSPTWYPopoverAnimationOptions)options;

- (void)presentPopoverFromRect:(CGRect)rect
                        inView:(UIView *)view
      permittedArrowDirections:(PSPTWYPopoverArrowDirection)arrowDirections
                      animated:(BOOL)animated
                       options:(PSPTWYPopoverAnimationOptions)options
                    completion:(void (^)(void))completion;

// Present popover from bar button items methods

- (void)presentPopoverFromBarButtonItem:(UIBarButtonItem *)item
               permittedArrowDirections:(PSPTWYPopoverArrowDirection)arrowDirections
                               animated:(BOOL)animated;

- (void)presentPopoverFromBarButtonItem:(UIBarButtonItem *)item
               permittedArrowDirections:(PSPTWYPopoverArrowDirection)arrowDirections
                               animated:(BOOL)animated
                             completion:(void (^)(void))completion;

- (void)presentPopoverFromBarButtonItem:(UIBarButtonItem *)item
               permittedArrowDirections:(PSPTWYPopoverArrowDirection)arrowDirections
                               animated:(BOOL)animated
                                options:(PSPTWYPopoverAnimationOptions)options;

- (void)presentPopoverFromBarButtonItem:(UIBarButtonItem *)item
               permittedArrowDirections:(PSPTWYPopoverArrowDirection)arrowDirections
                               animated:(BOOL)animated
                                options:(PSPTWYPopoverAnimationOptions)options
                             completion:(void (^)(void))completion;

// Present popover as dialog methods

- (void)presentPopoverAsDialogAnimated:(BOOL)animated;

- (void)presentPopoverAsDialogAnimated:(BOOL)animated
                            completion:(void (^)(void))completion;

- (void)presentPopoverAsDialogAnimated:(BOOL)animated
                               options:(PSPTWYPopoverAnimationOptions)options;

- (void)presentPopoverAsDialogAnimated:(BOOL)animated
                               options:(PSPTWYPopoverAnimationOptions)options
                            completion:(void (^)(void))completion;

// Dismiss popover methods

- (void)dismissPopoverAnimated:(BOOL)animated;

- (void)dismissPopoverAnimated:(BOOL)animated
                    completion:(void (^)(void))completion;

- (void)dismissPopoverAnimated:(BOOL)animated
                       options:(PSPTWYPopoverAnimationOptions)aOptions;

- (void)dismissPopoverAnimated:(BOOL)animated
                       options:(PSPTWYPopoverAnimationOptions)aOptions
                    completion:(void (^)(void))completion;

// Misc

- (void)setPopoverContentSize:(CGSize)size animated:(BOOL)animated;
- (void)performWithoutAnimation:(void (^)(void))aBlock;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol PSPTWYPopoverControllerDelegate <NSObject>
@optional

- (BOOL)popoverControllerShouldDismissPopover:(PSPTWYPopoverController *)popoverController;

- (void)popoverControllerDidPresentPopover:(PSPTWYPopoverController *)popoverController;

- (void)popoverControllerDidDismissPopover:(PSPTWYPopoverController *)popoverController;

- (void)popoverController:(PSPTWYPopoverController *)popoverController willTranslatePopoverWithYOffset:(float *)value;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface PSPTWYPopoverTheme : NSObject

// These two can be BOOLs, because implicit casting
// between BOOLs and NSUIntegers works fine
@property (nonatomic, assign) BOOL usesRoundedArrow;
@property (nonatomic, assign) BOOL dimsBackgroundViewsTintColor;

@property (nonatomic, strong) UIColor *tintColor;
@property (nonatomic, strong) UIColor *fillTopColor;
@property (nonatomic, strong) UIColor *fillBottomColor;

@property (nonatomic, strong) UIColor *glossShadowColor;
@property (nonatomic, assign) CGSize   glossShadowOffset;
@property (nonatomic, assign) NSUInteger  glossShadowBlurRadius;

@property (nonatomic, assign) NSUInteger  borderWidth;
@property (nonatomic, assign) NSUInteger  arrowBase;
@property (nonatomic, assign) NSUInteger  arrowHeight;

@property (nonatomic, strong) UIColor *outerShadowColor;
@property (nonatomic, strong) UIColor *outerStrokeColor;
@property (nonatomic, assign) NSUInteger  outerShadowBlurRadius;
@property (nonatomic, assign) CGSize   outerShadowOffset;
@property (nonatomic, assign) NSUInteger  outerCornerRadius;
@property (nonatomic, assign) NSUInteger  minOuterCornerRadius;

@property (nonatomic, strong) UIColor *innerShadowColor;
@property (nonatomic, strong) UIColor *innerStrokeColor;
@property (nonatomic, assign) NSUInteger  innerShadowBlurRadius;
@property (nonatomic, assign) CGSize   innerShadowOffset;
@property (nonatomic, assign) NSUInteger  innerCornerRadius;

@property (nonatomic, assign) UIEdgeInsets viewContentInsets;

@property (nonatomic, strong) UIColor *overlayColor;

+ (instancetype)theme;
+ (instancetype)themeForIOS7;

@end

