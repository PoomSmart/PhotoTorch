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

#import "PSPTWYPopoverController.h"

#import <objc/runtime.h>

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
#define WY_BASE_SDK_7_ENABLED
#endif

#define WY_IS_IOS_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)

#define WY_IS_IOS_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)

#define WY_IS_IOS_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#define WY_IS_IOS_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

////////////////////////////////////////////////////////////////////////////////////////////////////////

static BOOL getValueOfColor(UIColor *color, CGFloat *red, CGFloat *green, CGFloat *blue, CGFloat *alpha)
{
	CGColorSpaceRef colorSpace = CGColorSpaceRetain(CGColorGetColorSpace(color.CGColor));
    CGColorSpaceModel colorSpaceModel = CGColorSpaceGetModel(colorSpace);
    CGColorSpaceRelease(colorSpace);
    
    CGFloat rFloat = 0.0, gFloat = 0.0, bFloat = 0.0, aFloat = 0.0;
    BOOL result = NO;
    
    if (colorSpaceModel == kCGColorSpaceModelRGB)
    {
        result = [color getRed:&rFloat green:&gFloat blue:&bFloat alpha:&aFloat];
    }
    else if (colorSpaceModel == kCGColorSpaceModelMonochrome)
    {
        result = [color getWhite:&rFloat alpha:&aFloat];
        gFloat = rFloat;
        bFloat = rFloat;
    }
    
    if (red) *red = rFloat;
    if (green) *green = gFloat;
    if (blue) *blue = bFloat;
    if (alpha) *alpha = aFloat;
    
    return result;
}

static UIColor *colorByLighten(UIColor *color, float d)
{
	CGFloat rFloat, gFloat, bFloat, aFloat;
    getValueOfColor(color, &rFloat, &gFloat, &bFloat, &aFloat);
    return [UIColor colorWithRed:MIN(rFloat + d, 1.0)
                           green:MIN(gFloat + d, 1.0)
                            blue:MIN(bFloat + d, 1.0)
                           alpha:1.0];
}

static UIColor *colorByDarken(UIColor *color, float d)
{
	CGFloat rFloat, gFloat, bFloat, aFloat;
    getValueOfColor(color, &rFloat, &gFloat, &bFloat, &aFloat);
	return [UIColor colorWithRed:MAX(rFloat - d, 0.0)
                           green:MAX(gFloat - d, 0.0)
                            blue:MAX(bFloat - d, 0.0)
                           alpha:1.0];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface PSPTWYPopoverArea : NSObject
{
}

@property (nonatomic, assign) PSPTWYPopoverArrowDirection arrowDirection;
@property (nonatomic, assign) CGSize areaSize;
@property (nonatomic, assign, readonly) float value;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark
#pragma mark - PSPTWYPopoverArea

@implementation PSPTWYPopoverArea

@synthesize arrowDirection;
@synthesize areaSize;
@synthesize value;

- (NSString*)description
{
    NSString* direction = @"";
    
    if (arrowDirection == PSPTWYPopoverArrowDirectionUp)
    {
        direction = @"UP";
    }
    else if (arrowDirection == PSPTWYPopoverArrowDirectionDown)
    {
        direction = @"DOWN";
    }
    else if (arrowDirection == PSPTWYPopoverArrowDirectionLeft)
    {
        direction = @"LEFT";
    }
    else if (arrowDirection == PSPTWYPopoverArrowDirectionRight)
    {
        direction = @"RIGHT";
    }
    else if (arrowDirection == PSPTWYPopoverArrowDirectionNone)
    {
        direction = @"NONE";
    }
    
    return [NSString stringWithFormat:@"%@ [ %f x %f ]", direction, areaSize.width, areaSize.height];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface PSPTWYPopoverTheme ()

- (NSArray *)observableKeypaths;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation PSPTWYPopoverTheme

@synthesize usesRoundedArrow;
@synthesize dimsBackgroundViewsTintColor;
@synthesize tintColor;
@synthesize fillTopColor;
@synthesize fillBottomColor;

@synthesize glossShadowColor;
@synthesize glossShadowOffset;
@synthesize glossShadowBlurRadius;

@synthesize borderWidth;
@synthesize arrowBase;
@synthesize arrowHeight;

@synthesize outerShadowColor;
@synthesize outerStrokeColor;
@synthesize outerShadowBlurRadius;
@synthesize outerShadowOffset;
@synthesize outerCornerRadius;
@synthesize minOuterCornerRadius;

@synthesize innerShadowColor;
@synthesize innerStrokeColor;
@synthesize innerShadowBlurRadius;
@synthesize innerShadowOffset;
@synthesize innerCornerRadius;

@synthesize viewContentInsets;

@synthesize overlayColor;

+ (id)theme {
    
    PSPTWYPopoverTheme *result = [PSPTWYPopoverTheme themeForIOS7];
    
    return result;
}

+ (id)themeForIOS7 {
    
    PSPTWYPopoverTheme *result = [[PSPTWYPopoverTheme alloc] init];
    
    result.usesRoundedArrow = YES;
    result.dimsBackgroundViewsTintColor = YES;
    result.tintColor = [UIColor colorWithRed:244./255. green:244./255. blue:244./255. alpha:1.0];
    result.outerStrokeColor = [UIColor clearColor];
    result.innerStrokeColor = [UIColor clearColor];
    result.fillTopColor = nil;
    result.fillBottomColor = nil;
    result.glossShadowColor = nil;
    result.glossShadowOffset = CGSizeZero;
    result.glossShadowBlurRadius = 0;
    result.borderWidth = 0;
    result.arrowBase = 25;
    result.arrowHeight = 13;
    result.outerShadowColor = [UIColor clearColor];
    result.outerShadowBlurRadius = 0;
    result.outerShadowOffset = CGSizeZero;
    result.outerCornerRadius = 5;
    result.minOuterCornerRadius = 0;
    result.innerShadowColor = [UIColor clearColor];
    result.innerShadowBlurRadius = 0;
    result.innerShadowOffset = CGSizeZero;
    result.innerCornerRadius = 0;
    result.viewContentInsets = UIEdgeInsetsZero;
    result.overlayColor = [UIColor colorWithWhite:0 alpha:0.15];
    
    return result;
}

- (NSUInteger)innerCornerRadius
{
    float result = innerCornerRadius;
    
    if (borderWidth == 0)
    {
        result = 0;
        
        if (outerCornerRadius > 0)
        {
            result = outerCornerRadius;
        }
    }
    
    return result;
}

- (CGSize)outerShadowOffset
{
    CGSize result = outerShadowOffset;
    
    result.width = MIN(result.width, outerShadowBlurRadius);
    result.height = MIN(result.height, outerShadowBlurRadius);
    
    return result;
}

- (UIColor *)innerStrokeColor
{
    UIColor *result = innerStrokeColor;
    
    if (result == nil)
    {
        result = colorByDarken(self.fillTopColor, 0.6);
    }
    
    return result;
}

- (UIColor *)outerStrokeColor
{
    UIColor *result = outerStrokeColor;
    
    if (result == nil)
    {
        result = colorByDarken(self.fillTopColor, 0.6);
    }
    
    return result;
}

- (UIColor *)glossShadowColor
{
    UIColor *result = glossShadowColor;
    
    if (result == nil)
    {
        result = colorByLighten(self.fillTopColor, 0.2);
    }
    
    return result;
}

- (UIColor *)fillTopColor
{
    UIColor *result = fillTopColor;
    
    if (result == nil)
    {
        result = tintColor;
    }
    
    return result;
}

- (UIColor *)fillBottomColor
{
    UIColor *result = fillBottomColor;
    
    if (result == nil)
    {
        result = self.fillTopColor;
    }
    
    return result;
}

- (NSArray *)observableKeypaths {
    return [NSArray arrayWithObjects:@"tintColor", @"outerStrokeColor", @"innerStrokeColor", @"fillTopColor", @"fillBottomColor", @"glossShadowColor", @"glossShadowOffset", @"glossShadowBlurRadius", @"borderWidth", @"arrowBase", @"arrowHeight", @"outerShadowColor", @"outerShadowBlurRadius", @"outerShadowOffset", @"outerCornerRadius", @"innerShadowColor", @"innerShadowBlurRadius", @"innerShadowOffset", @"innerCornerRadius", @"viewContentInsets", @"overlayColor", nil];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface PSPTWYPopoverBackgroundInnerView : UIView

@property (nonatomic, strong) UIColor *innerStrokeColor;

@property (nonatomic, strong) UIColor *gradientTopColor;
@property (nonatomic, strong) UIColor *gradientBottomColor;
@property (nonatomic, assign) float  gradientHeight;
@property (nonatomic, assign) float  gradientTopPosition;

@property (nonatomic, strong) UIColor *innerShadowColor;
@property (nonatomic, assign) CGSize   innerShadowOffset;
@property (nonatomic, assign) float  innerShadowBlurRadius;
@property (nonatomic, assign) float  innerCornerRadius;

@property (nonatomic, assign) float  navigationBarHeight;
@property (nonatomic, assign) BOOL     wantsDefaultContentAppearance;
@property (nonatomic, assign) float  borderWidth;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark
#pragma mark - PSPTWYPopoverInnerView

@implementation PSPTWYPopoverBackgroundInnerView

@synthesize innerStrokeColor;

@synthesize gradientTopColor;
@synthesize gradientBottomColor;
@synthesize gradientHeight;
@synthesize gradientTopPosition;

@synthesize innerShadowColor;
@synthesize innerShadowOffset;
@synthesize innerShadowBlurRadius;
@synthesize innerCornerRadius;

@synthesize navigationBarHeight;
@synthesize wantsDefaultContentAppearance;
@synthesize borderWidth;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Gradient Declarations
    NSArray* fillGradientColors = [NSArray arrayWithObjects:
                                   (id)gradientTopColor.CGColor,
                                   (id)gradientBottomColor.CGColor, nil];
    
    CGFloat fillGradientLocations[2] = { 0, 1 };
    
    CGGradientRef fillGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)fillGradientColors, fillGradientLocations);
    
    //// innerRect Drawing
    float barHeight = (wantsDefaultContentAppearance == NO) ? navigationBarHeight : 0;
    float cornerRadius = (wantsDefaultContentAppearance == NO) ? innerCornerRadius : 0;
    
    CGRect innerRect = CGRectMake(CGRectGetMinX(rect), CGRectGetMinY(rect) + barHeight, CGRectGetWidth(rect) , CGRectGetHeight(rect) - barHeight);
    
    UIBezierPath* rectPath = [UIBezierPath bezierPathWithRect:innerRect];
    
    UIBezierPath* roundedRectPath = [UIBezierPath bezierPathWithRoundedRect:innerRect cornerRadius:cornerRadius + 1];
    
    if (wantsDefaultContentAppearance == NO && borderWidth > 0)
    {
        CGContextSaveGState(context);
        {
            [rectPath appendPath:roundedRectPath];
            rectPath.usesEvenOddFillRule = YES;
            [rectPath addClip];
            
            CGContextDrawLinearGradient(context, fillGradient,
                                        CGPointMake(0, -gradientTopPosition),
                                        CGPointMake(0, -gradientTopPosition + gradientHeight),
                                        0);
        }
        CGContextRestoreGState(context);
    }
    
    CGContextSaveGState(context);
    {
        if (wantsDefaultContentAppearance == NO && borderWidth > 0)
        {
            [roundedRectPath addClip];
            CGContextSetShadowWithColor(context, innerShadowOffset, innerShadowBlurRadius, innerShadowColor.CGColor);
        }
        
        UIBezierPath* inRoundedRectPath = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(innerRect, 0.5, 0.5) cornerRadius:cornerRadius];
        
        if (borderWidth == 0)
        {
            inRoundedRectPath = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(innerRect, 0.5, 0.5) byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];
        }
        
        [self.innerStrokeColor setStroke];
        inRoundedRectPath.lineWidth = 1;
        [inRoundedRectPath stroke];
    }
    
    CGContextRestoreGState(context);
    
    CGGradientRelease(fillGradient);
    CGColorSpaceRelease(colorSpace);
}

- (void)dealloc
{
    innerShadowColor = nil;
    innerStrokeColor = nil;
    gradientTopColor = nil;
    gradientBottomColor = nil;
    [super dealloc];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol PSPTWYPopoverOverlayViewDelegate;

@interface PSPTWYPopoverOverlayView : UIView
{
    BOOL testHits;
}

@property(nonatomic, assign) id <PSPTWYPopoverOverlayViewDelegate> delegate;
@property(nonatomic, unsafe_unretained) NSArray *passthroughViews;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark
#pragma mark - PSPTWYPopoverOverlayViewDelegate

@protocol PSPTWYPopoverOverlayViewDelegate <NSObject>

@optional
- (BOOL)dismissOnPassthroughViewTap;
- (void)popoverOverlayViewDidTouch:(PSPTWYPopoverOverlayView *)overlayView;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark
#pragma mark - PSPTWYPopoverOverlayView

@implementation PSPTWYPopoverOverlayView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (testHits) {
        return nil;
    }
    
    UIView *view = [super hitTest:point withEvent:event];
    
    if (view == self)
    {
        testHits = YES;
        UIView *superHitView = [self.superview hitTest:point withEvent:event];
        testHits = NO;
        
        if ([self isPassthroughView:superHitView])
        {
            if ([self.delegate dismissOnPassthroughViewTap])
            {
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    if ([self.delegate respondsToSelector:@selector(popoverOverlayViewDidTouch:)])
                    {
                        [self.delegate popoverOverlayViewDidTouch:self];
                    }
                });
            }
            return superHitView;
        }
    }
    
    return view;
}

- (BOOL)isPassthroughView:(UIView *)view
{
	if (view == nil)
    {
		return NO;
	}
	
	if ([self.passthroughViews containsObject:view])
    {
		return YES;
	}
	
	return [self isPassthroughView:view.superview];
}

/**
 * @note This empty method is meaningful.
 *       If the method is not defined, touch event isn't capture in iOS6.
 */
- (void)drawRect:(CGRect)rect
{
}

#pragma mark - UIAccessibility

- (void)accessibilityElementDidBecomeFocused {
    self.accessibilityLabel = NSLocalizedString(@"Double-tap to dismiss pop-up window.", nil);
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark
#pragma mark - PSPTWYPopoverBackgroundViewDelegate

@protocol PSPTWYPopoverBackgroundViewDelegate <NSObject>

@optional
- (void)popoverBackgroundViewDidTouchOutside:(PSPTWYPopoverBackgroundView *)backgroundView;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface PSPTWYPopoverBackgroundView ()
{
    PSPTWYPopoverBackgroundInnerView *innerView;
    CGSize contentSize;
}

@property(nonatomic, assign) id <PSPTWYPopoverBackgroundViewDelegate> delegate;

@property (nonatomic, assign) PSPTWYPopoverArrowDirection arrowDirection;

@property (nonatomic, strong, readonly) UIView *contentView;
@property (nonatomic, assign, readonly) float navigationBarHeight;
@property (nonatomic, assign, readonly) UIEdgeInsets outerShadowInsets;
@property (nonatomic, assign) float arrowOffset;
@property (nonatomic, assign) BOOL wantsDefaultContentAppearance;

@property (nonatomic, assign, getter = isAppearing) BOOL appearing;

- (void)tapOut;

- (void)setViewController:(UIViewController *)viewController;

- (CGRect)outerRect;
- (CGRect)innerRect;
- (CGRect)arrowRect;

- (CGRect)outerRect:(CGRect)rect arrowDirection:(PSPTWYPopoverArrowDirection)aArrowDirection;
- (CGRect)innerRect:(CGRect)rect arrowDirection:(PSPTWYPopoverArrowDirection)aArrowDirection;
- (CGRect)arrowRect:(CGRect)rect arrowDirection:(PSPTWYPopoverArrowDirection)aArrowDirection;

- (id)initWithContentSize:(CGSize)contentSize;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark
#pragma mark - PSPTWYPopoverBackgroundView

@implementation PSPTWYPopoverBackgroundView

@synthesize tintColor;

@synthesize fillTopColor;
@synthesize fillBottomColor;
@synthesize glossShadowColor;
@synthesize glossShadowOffset;
@synthesize glossShadowBlurRadius;
@synthesize borderWidth;
@synthesize arrowBase;
@synthesize arrowHeight;
@synthesize outerShadowColor;
@synthesize outerStrokeColor;
@synthesize outerShadowBlurRadius;
@synthesize outerShadowOffset;
@synthesize outerCornerRadius;
@synthesize minOuterCornerRadius;
@synthesize innerShadowColor;
@synthesize innerStrokeColor;
@synthesize innerShadowBlurRadius;
@synthesize innerShadowOffset;
@synthesize innerCornerRadius;
@synthesize viewContentInsets;

@synthesize arrowDirection;
@synthesize contentView;
@synthesize arrowOffset;
@synthesize navigationBarHeight;
@synthesize wantsDefaultContentAppearance;

@synthesize outerShadowInsets;

- (id)initWithContentSize:(CGSize)aContentSize
{
    self = [super initWithFrame:CGRectMake(0, 0, aContentSize.width, aContentSize.height)];
    
    if (self != nil)
    {
        contentSize = aContentSize;
        
        self.autoresizesSubviews = NO;
        self.backgroundColor = [UIColor clearColor];
        
        self.arrowDirection = PSPTWYPopoverArrowDirectionDown;
        self.arrowOffset = 0;
        
        self.layer.name = @"parent";
        
        self.layer.drawsAsynchronously = YES;
        
        self.layer.contentsScale = [UIScreen mainScreen].scale;
        self.layer.delegate = self;
    }
    
    return self;
}

- (void)tapOut
{
    [self.delegate popoverBackgroundViewDidTouchOutside:self];
}

- (void)setArrowOffset:(float)value
{
    float coef = 1;
    
    if (value != 0)
    {
        coef = value / ABS(value);
        
        value = ABS(value);
        
        CGRect outerRect = [self outerRect];
        
        float delta = self.arrowBase / 2. + .5;
        
        delta  += MIN(minOuterCornerRadius, outerCornerRadius);
        
        outerRect = CGRectInset(outerRect, delta, delta);
        
        if (arrowDirection == PSPTWYPopoverArrowDirectionUp || arrowDirection == PSPTWYPopoverArrowDirectionDown)
        {
            value += coef * self.outerShadowOffset.width;
            value = MIN(value, CGRectGetWidth(outerRect) / 2);
        }
        
        if (arrowDirection == PSPTWYPopoverArrowDirectionLeft || arrowDirection == PSPTWYPopoverArrowDirectionRight)
        {
            value += coef * self.outerShadowOffset.height;
            value = MIN(value, CGRectGetHeight(outerRect) / 2);
        }
    }
    else
    {
        if (arrowDirection == PSPTWYPopoverArrowDirectionUp || arrowDirection == PSPTWYPopoverArrowDirectionDown)
        {
            value += self.outerShadowOffset.width;
        }
        
        if (arrowDirection == PSPTWYPopoverArrowDirectionLeft || arrowDirection == PSPTWYPopoverArrowDirectionRight)
        {
            value += self.outerShadowOffset.height;
        }
    }
    
    arrowOffset = value * coef;
}

- (void)setViewController:(UIViewController *)viewController
{
    contentView = viewController.view;
    
    contentView.frame = CGRectIntegral(CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height));
    
    [self addSubview:contentView];
    
    navigationBarHeight = 0;
    
    if ([viewController isKindOfClass:[UINavigationController class]])
    {
        UINavigationController* navigationController = (UINavigationController*)viewController;
        navigationBarHeight = navigationController.navigationBarHidden? 0 : navigationController.navigationBar.bounds.size.height;
    }
    
    contentView.frame = CGRectIntegral([self innerRect]);
    
    if (innerView == nil)
    {
        innerView = [[PSPTWYPopoverBackgroundInnerView alloc] initWithFrame:contentView.frame];
        innerView.userInteractionEnabled = NO;
        
        innerView.gradientTopColor = self.fillTopColor;
        innerView.gradientBottomColor = self.fillBottomColor;
        innerView.innerShadowColor = innerShadowColor;
        innerView.innerStrokeColor = self.innerStrokeColor;
        innerView.innerShadowOffset = innerShadowOffset;
        innerView.innerCornerRadius = self.innerCornerRadius;
        innerView.innerShadowBlurRadius = innerShadowBlurRadius;
        innerView.borderWidth = self.borderWidth;
    }
    
    innerView.navigationBarHeight = navigationBarHeight;
    innerView.gradientHeight = self.frame.size.height - 2 * outerShadowBlurRadius;
    innerView.gradientTopPosition = contentView.frame.origin.y - self.outerShadowInsets.top;
    innerView.wantsDefaultContentAppearance = wantsDefaultContentAppearance;
    
    [self insertSubview:innerView aboveSubview:contentView];
    
    innerView.frame = CGRectIntegral(contentView.frame);
    
    [self.layer setNeedsDisplay];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize result = size;
    
    result.width += 2 * (borderWidth + outerShadowBlurRadius);
    result.height += borderWidth + 2 * outerShadowBlurRadius;
    
    if (navigationBarHeight == 0)
    {
        result.height += borderWidth;
    }
    
    if (arrowDirection == PSPTWYPopoverArrowDirectionUp || arrowDirection == PSPTWYPopoverArrowDirectionDown)
    {
        result.height += arrowHeight;
    }
    
    if (arrowDirection == PSPTWYPopoverArrowDirectionLeft || arrowDirection == PSPTWYPopoverArrowDirectionRight)
    {
        result.width += arrowHeight;
    }
    
    return result;
}

- (void)sizeToFit
{
    CGSize size = [self sizeThatFits:contentSize];
    self.bounds = CGRectMake(0, 0, size.width, size.height);
}

#pragma mark Drawing

- (void)setNeedsDisplay
{
    [super setNeedsDisplay];
    
    [self.layer setNeedsDisplay];
    
    if (innerView)
    {
        innerView.gradientTopColor = self.fillTopColor;
        innerView.gradientBottomColor = self.fillBottomColor;
        innerView.innerShadowColor = innerShadowColor;
        innerView.innerStrokeColor = self.innerStrokeColor;
        innerView.innerShadowOffset = innerShadowOffset;
        innerView.innerCornerRadius = self.innerCornerRadius;
        innerView.innerShadowBlurRadius = innerShadowBlurRadius;
        innerView.borderWidth = self.borderWidth;
        
        innerView.navigationBarHeight = navigationBarHeight;
        innerView.gradientHeight = self.frame.size.height - 2 * outerShadowBlurRadius;
        innerView.gradientTopPosition = contentView.frame.origin.y - self.outerShadowInsets.top;
        innerView.wantsDefaultContentAppearance = wantsDefaultContentAppearance;
        
        [innerView setNeedsDisplay];
    }
}

#pragma mark CALayerDelegate

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context
{
    if ([layer.name isEqualToString:@"parent"])
    {
        UIGraphicsPushContext(context);
        //CGContextSetShouldAntialias(context, YES);
        //CGContextSetAllowsAntialiasing(context, YES);
        
        //// General Declarations
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        //// Gradient Declarations
        NSArray* fillGradientColors = [NSArray arrayWithObjects:
                                       (id)self.fillTopColor.CGColor,
                                       (id)self.fillBottomColor.CGColor, nil];
        
        CGFloat fillGradientLocations[2] = {0, 1};
        CGGradientRef fillGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)fillGradientColors, fillGradientLocations);
        
        // Frames
        CGRect rect = self.bounds;
        
        CGRect outerRect = [self outerRect:rect arrowDirection:self.arrowDirection];
        CGRect insetRect = CGRectInset(outerRect, 0.5, 0.5);
        if (!CGRectIsEmpty(insetRect) && !CGRectIsInfinite(insetRect)) {
            outerRect = insetRect;
        }
        
        // Inner Path
        CGMutablePathRef outerPathRef = CGPathCreateMutable();
        
        CGPoint arrowTipPoint = CGPointZero;
        CGPoint arrowBasePointA = CGPointZero;
        CGPoint arrowBasePointB = CGPointZero;
        
        float reducedOuterCornerRadius = 0;
        
        if (arrowDirection == PSPTWYPopoverArrowDirectionUp || arrowDirection == PSPTWYPopoverArrowDirectionDown)
        {
            if (arrowOffset >= 0)
            {
                reducedOuterCornerRadius = CGRectGetMaxX(outerRect) - (CGRectGetMidX(outerRect) + arrowOffset + arrowBase / 2);
            }
            else
            {
                reducedOuterCornerRadius = (CGRectGetMidX(outerRect) + arrowOffset - arrowBase / 2) - CGRectGetMinX(outerRect);
            }
        }
        else if (arrowDirection == PSPTWYPopoverArrowDirectionLeft || arrowDirection == PSPTWYPopoverArrowDirectionRight)
        {
            if (arrowOffset >= 0)
            {
                reducedOuterCornerRadius = CGRectGetMaxY(outerRect) - (CGRectGetMidY(outerRect) + arrowOffset + arrowBase / 2);
            }
            else
            {
                reducedOuterCornerRadius = (CGRectGetMidY(outerRect) + arrowOffset - arrowBase / 2) - CGRectGetMinY(outerRect);
            }
        }
        
        reducedOuterCornerRadius = MIN(reducedOuterCornerRadius, outerCornerRadius);
        
        CGFloat roundedArrowControlLength = arrowBase / 5.0f;
        if (arrowDirection == PSPTWYPopoverArrowDirectionUp)
        {
            arrowTipPoint = CGPointMake(CGRectGetMidX(outerRect) + arrowOffset,
                                        CGRectGetMinY(outerRect) - arrowHeight);
            arrowBasePointA = CGPointMake(arrowTipPoint.x - arrowBase / 2,
                                          arrowTipPoint.y + arrowHeight);
            arrowBasePointB = CGPointMake(arrowTipPoint.x + arrowBase / 2,
                                          arrowTipPoint.y + arrowHeight);
            
            CGPathMoveToPoint(outerPathRef, NULL, arrowBasePointA.x, arrowBasePointA.y);

            if (self.usesRoundedArrow)
            {
                CGPathAddCurveToPoint(outerPathRef, NULL,
                                      arrowBasePointA.x + roundedArrowControlLength, arrowBasePointA.y,
                                      arrowTipPoint.x - (roundedArrowControlLength * 0.75f), arrowTipPoint.y,
                                      arrowTipPoint.x, arrowTipPoint.y);
                CGPathAddCurveToPoint(outerPathRef, NULL,
                                      arrowTipPoint.x + (roundedArrowControlLength * 0.75f), arrowTipPoint.y,
                                      arrowBasePointB.x - roundedArrowControlLength, arrowBasePointB.y,
                                      arrowBasePointB.x, arrowBasePointB.y);
            }
            else
            {
                CGPathAddLineToPoint(outerPathRef, NULL, arrowTipPoint.x, arrowTipPoint.y);
                CGPathAddLineToPoint(outerPathRef, NULL, arrowBasePointB.x, arrowBasePointB.y);
            }
            
            CGPathAddArcToPoint(outerPathRef, NULL, CGRectGetMaxX(outerRect), CGRectGetMinY(outerRect),
                                CGRectGetMaxX(outerRect), CGRectGetMaxY(outerRect),
                                (arrowOffset >= 0) ? reducedOuterCornerRadius : outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL, CGRectGetMaxX(outerRect), CGRectGetMaxY(outerRect),
                                CGRectGetMinX(outerRect), CGRectGetMaxY(outerRect),
                                outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL, CGRectGetMinX(outerRect), CGRectGetMaxY(outerRect),
                                CGRectGetMinX(outerRect), CGRectGetMinY(outerRect),
                                outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL, CGRectGetMinX(outerRect), CGRectGetMinY(outerRect),
                                CGRectGetMaxX(outerRect), CGRectGetMinY(outerRect),
                                (arrowOffset < 0) ? reducedOuterCornerRadius : outerCornerRadius);
            
            CGPathAddLineToPoint(outerPathRef, NULL, arrowBasePointA.x, arrowBasePointA.y);
        }
        else if (arrowDirection == PSPTWYPopoverArrowDirectionDown)
        {
            arrowTipPoint = CGPointMake(CGRectGetMidX(outerRect) + arrowOffset,
                                        CGRectGetMaxY(outerRect) + arrowHeight);
            arrowBasePointA = CGPointMake(arrowTipPoint.x + arrowBase / 2,
                                          arrowTipPoint.y - arrowHeight);
            arrowBasePointB = CGPointMake(arrowTipPoint.x - arrowBase / 2,
                                          arrowTipPoint.y - arrowHeight);
            
            CGPathMoveToPoint(outerPathRef, NULL, arrowBasePointA.x, arrowBasePointA.y);

            if (self.usesRoundedArrow)
            {
                CGPathAddCurveToPoint(outerPathRef, NULL,
                                      arrowBasePointA.x - roundedArrowControlLength, arrowBasePointA.y,
                                      arrowTipPoint.x + (roundedArrowControlLength * 0.75f), arrowTipPoint.y,
                                      arrowTipPoint.x, arrowTipPoint.y);
                CGPathAddCurveToPoint(outerPathRef, NULL,
                                      arrowTipPoint.x - (roundedArrowControlLength * 0.75f), arrowTipPoint.y,
                                      arrowBasePointB.x + roundedArrowControlLength, arrowBasePointA.y,
                                      arrowBasePointB.x, arrowBasePointB.y);
            }
            else
            {
                CGPathAddLineToPoint(outerPathRef, NULL, arrowTipPoint.x, arrowTipPoint.y);
                CGPathAddLineToPoint(outerPathRef, NULL, arrowBasePointB.x, arrowBasePointB.y);
            }
            
            CGPathAddArcToPoint(outerPathRef, NULL,
                                CGRectGetMinX(outerRect), CGRectGetMaxY(outerRect),
                                CGRectGetMinX(outerRect), CGRectGetMinY(outerRect),
                                (arrowOffset < 0) ? reducedOuterCornerRadius : outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL,
                                CGRectGetMinX(outerRect), CGRectGetMinY(outerRect),
                                CGRectGetMaxX(outerRect), CGRectGetMinY(outerRect),
                                outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL,
                                CGRectGetMaxX(outerRect), CGRectGetMinY(outerRect),
                                CGRectGetMaxX(outerRect), CGRectGetMaxY(outerRect),
                                outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL,
                                CGRectGetMaxX(outerRect), CGRectGetMaxY(outerRect),
                                CGRectGetMinX(outerRect), CGRectGetMaxY(outerRect),
                                (arrowOffset >= 0) ? reducedOuterCornerRadius : outerCornerRadius);
            
            CGPathAddLineToPoint(outerPathRef, NULL, arrowBasePointA.x, arrowBasePointA.y);
        }
        else if (arrowDirection == PSPTWYPopoverArrowDirectionLeft)
        {
            arrowTipPoint = CGPointMake(CGRectGetMinX(outerRect) - arrowHeight,
                                        CGRectGetMidY(outerRect) + arrowOffset);
            arrowBasePointA = CGPointMake(arrowTipPoint.x + arrowHeight,
                                          arrowTipPoint.y + arrowBase / 2);
            arrowBasePointB = CGPointMake(arrowTipPoint.x + arrowHeight,
                                          arrowTipPoint.y - arrowBase / 2);

            CGPathMoveToPoint(outerPathRef, NULL, arrowBasePointA.x, arrowBasePointA.y);

            if (self.usesRoundedArrow)
            {
                CGPathAddCurveToPoint(outerPathRef, NULL,
                                      arrowBasePointA.x, arrowBasePointA.y - roundedArrowControlLength,
                                      arrowTipPoint.x, arrowTipPoint.y + (roundedArrowControlLength * 0.75f),
                                      arrowTipPoint.x, arrowTipPoint.y);
                CGPathAddCurveToPoint(outerPathRef, NULL,
                                      arrowTipPoint.x, arrowTipPoint.y - (roundedArrowControlLength * 0.75f),
                                      arrowBasePointB.x, arrowBasePointB.y + roundedArrowControlLength,
                                      arrowBasePointB.x, arrowBasePointB.y);
            }
            else
            {
                CGPathAddLineToPoint(outerPathRef, NULL, arrowTipPoint.x, arrowTipPoint.y);
                CGPathAddLineToPoint(outerPathRef, NULL, arrowBasePointB.x, arrowBasePointB.y);
            }
            
            CGPathAddArcToPoint(outerPathRef, NULL,
                                CGRectGetMinX(outerRect), CGRectGetMinY(outerRect),
                                CGRectGetMaxX(outerRect), CGRectGetMinY(outerRect),
                                (arrowOffset < 0) ? reducedOuterCornerRadius : outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL,
                                CGRectGetMaxX(outerRect), CGRectGetMinY(outerRect),
                                CGRectGetMaxX(outerRect), CGRectGetMaxY(outerRect),
                                outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL,
                                CGRectGetMaxX(outerRect), CGRectGetMaxY(outerRect),
                                CGRectGetMinX(outerRect), CGRectGetMaxY(outerRect),
                                outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL,
                                CGRectGetMinX(outerRect), CGRectGetMaxY(outerRect),
                                CGRectGetMinX(outerRect), CGRectGetMinY(outerRect),
                                (arrowOffset >= 0) ? reducedOuterCornerRadius : outerCornerRadius);
            
            CGPathAddLineToPoint(outerPathRef, NULL, arrowBasePointA.x, arrowBasePointA.y);
        }
        else if (arrowDirection == PSPTWYPopoverArrowDirectionRight)
        {
            arrowTipPoint = CGPointMake(CGRectGetMaxX(outerRect) + arrowHeight,
                                        CGRectGetMidY(outerRect) + arrowOffset);
            arrowBasePointA = CGPointMake(arrowTipPoint.x - arrowHeight,
                                          arrowTipPoint.y - arrowBase / 2);
            arrowBasePointB = CGPointMake(arrowTipPoint.x - arrowHeight,
                                          arrowTipPoint.y + arrowBase / 2);

            CGPathMoveToPoint(outerPathRef, NULL, arrowBasePointA.x, arrowBasePointA.y);

            if (self.usesRoundedArrow)
            {
                CGPathAddCurveToPoint(outerPathRef, NULL,
                                      arrowBasePointA.x, arrowBasePointA.y + roundedArrowControlLength,
                                      arrowTipPoint.x, arrowTipPoint.y - (roundedArrowControlLength * 0.75f),
                                      arrowTipPoint.x, arrowTipPoint.y);
                CGPathAddCurveToPoint(outerPathRef, NULL,
                                      arrowTipPoint.x, arrowTipPoint.y + (roundedArrowControlLength * 0.75f),
                                      arrowBasePointB.x, arrowBasePointB.y - roundedArrowControlLength,
                                      arrowBasePointB.x, arrowBasePointB.y);
            }
            else
            {
                CGPathAddLineToPoint(outerPathRef, NULL, arrowTipPoint.x, arrowTipPoint.y);
                CGPathAddLineToPoint(outerPathRef, NULL, arrowBasePointB.x, arrowBasePointB.y);
            }
            
            CGPathAddArcToPoint(outerPathRef, NULL,
                                CGRectGetMaxX(outerRect), CGRectGetMaxY(outerRect),
                                CGRectGetMinX(outerRect), CGRectGetMaxY(outerRect),
                                (arrowOffset >= 0) ? reducedOuterCornerRadius : outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL,
                                CGRectGetMinX(outerRect), CGRectGetMaxY(outerRect),
                                CGRectGetMinX(outerRect), CGRectGetMinY(outerRect),
                                outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL,
                                CGRectGetMinX(outerRect), CGRectGetMinY(outerRect),
                                CGRectGetMaxX(outerRect), CGRectGetMinY(outerRect),
                                outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL,
                                CGRectGetMaxX(outerRect), CGRectGetMinY(outerRect),
                                CGRectGetMaxX(outerRect), CGRectGetMaxY(outerRect),
                                (arrowOffset < 0) ? reducedOuterCornerRadius : outerCornerRadius);
            
            CGPathAddLineToPoint(outerPathRef, NULL, arrowBasePointA.x, arrowBasePointA.y);
        }
        else if (arrowDirection == PSPTWYPopoverArrowDirectionNone)
        {
            CGPoint origin = CGPointMake(CGRectGetMaxX(outerRect), CGRectGetMidY(outerRect));
            
            CGPathMoveToPoint(outerPathRef, NULL, origin.x, origin.y);
            
            CGPathAddLineToPoint(outerPathRef, NULL, CGRectGetMaxX(outerRect), CGRectGetMidY(outerRect));
            CGPathAddLineToPoint(outerPathRef, NULL, CGRectGetMaxX(outerRect), CGRectGetMidY(outerRect));
            
            CGPathAddArcToPoint(outerPathRef, NULL,
                                CGRectGetMaxX(outerRect), CGRectGetMaxY(outerRect),
                                CGRectGetMinX(outerRect), CGRectGetMaxY(outerRect),
                                outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL,
                                CGRectGetMinX(outerRect), CGRectGetMaxY(outerRect),
                                CGRectGetMinX(outerRect), CGRectGetMinY(outerRect),
                                outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL,
                                CGRectGetMinX(outerRect), CGRectGetMinY(outerRect),
                                CGRectGetMaxX(outerRect), CGRectGetMinY(outerRect),
                                outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL,
                                CGRectGetMaxX(outerRect), CGRectGetMinY(outerRect),
                                CGRectGetMaxX(outerRect), CGRectGetMaxY(outerRect),
                                outerCornerRadius);
            
            CGPathAddLineToPoint(outerPathRef, NULL, origin.x, origin.y);
        }
        
        CGPathCloseSubpath(outerPathRef);
        UIBezierPath* outerRectPath = [UIBezierPath bezierPathWithCGPath:outerPathRef];
        
        CGContextSaveGState(context);
        {
            CGContextSetShadowWithColor(context, self.outerShadowOffset, outerShadowBlurRadius, outerShadowColor.CGColor);
            CGContextBeginTransparencyLayer(context, NULL);
            [outerRectPath addClip];
            CGRect outerRectBounds = CGPathGetPathBoundingBox(outerRectPath.CGPath);
            CGContextDrawLinearGradient(context, fillGradient,
                                        CGPointMake(CGRectGetMidX(outerRectBounds), CGRectGetMinY(outerRectBounds)),
                                        CGPointMake(CGRectGetMidX(outerRectBounds), CGRectGetMaxY(outerRectBounds)),
                                        0);
            CGContextEndTransparencyLayer(context);
        }
        CGContextRestoreGState(context);
        
        ////// outerRect Inner Shadow
        CGRect outerRectBorderRect = CGRectInset([outerRectPath bounds], -glossShadowBlurRadius, -glossShadowBlurRadius);
        outerRectBorderRect = CGRectOffset(outerRectBorderRect, -glossShadowOffset.width, -glossShadowOffset.height);
        outerRectBorderRect = CGRectInset(CGRectUnion(outerRectBorderRect, [outerRectPath bounds]), -1, -1);
        
        UIBezierPath* outerRectNegativePath = [UIBezierPath bezierPathWithRect: outerRectBorderRect];
        [outerRectNegativePath appendPath: outerRectPath];
        outerRectNegativePath.usesEvenOddFillRule = YES;
        
        CGContextSaveGState(context);
        {
            float xOffset = glossShadowOffset.width + round(outerRectBorderRect.size.width);
            float yOffset = glossShadowOffset.height;
            CGContextSetShadowWithColor(context,
                                        CGSizeMake(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset)),
                                        glossShadowBlurRadius,
                                        self.glossShadowColor.CGColor);
            
            [outerRectPath addClip];
            CGAffineTransform transform = CGAffineTransformMakeTranslation(-round(outerRectBorderRect.size.width), 0);
            [outerRectNegativePath applyTransform: transform];
            [[UIColor grayColor] setFill];
            [outerRectNegativePath fill];
        }
        CGContextRestoreGState(context);
        
        [self.outerStrokeColor setStroke];
        outerRectPath.lineWidth = 0;
        [outerRectPath stroke];
        
        //// Cleanup
        CFRelease(outerPathRef);
        CGGradientRelease(fillGradient);
        CGColorSpaceRelease(colorSpace);
        
        UIGraphicsPopContext();
    }
}

#pragma mark Private

- (CGRect)outerRect
{
    return [self outerRect:self.bounds arrowDirection:self.arrowDirection];
}

- (CGRect)innerRect
{
    return [self innerRect:self.bounds arrowDirection:self.arrowDirection];
}

- (CGRect)arrowRect
{
    return [self arrowRect:self.bounds arrowDirection:self.arrowDirection];
}

- (CGRect)outerRect:(CGRect)rect arrowDirection:(PSPTWYPopoverArrowDirection)aArrowDirection
{
    CGRect result = rect;
    
    if (aArrowDirection == PSPTWYPopoverArrowDirectionUp || arrowDirection == PSPTWYPopoverArrowDirectionDown)
    {
        result.size.height -= arrowHeight;
        
        if (aArrowDirection == PSPTWYPopoverArrowDirectionUp)
        {
            result = CGRectOffset(result, 0, arrowHeight);
        }
    }
    
    if (aArrowDirection == PSPTWYPopoverArrowDirectionLeft || arrowDirection == PSPTWYPopoverArrowDirectionRight)
    {
        result.size.width -= arrowHeight;
        
        if (aArrowDirection == PSPTWYPopoverArrowDirectionLeft)
        {
            result = CGRectOffset(result, arrowHeight, 0);
        }
    }
    
    result = CGRectInset(result, outerShadowBlurRadius, outerShadowBlurRadius);
    result.origin.x -= self.outerShadowOffset.width;
    result.origin.y -= self.outerShadowOffset.height;
    
    return result;
}

- (CGRect)innerRect:(CGRect)rect arrowDirection:(PSPTWYPopoverArrowDirection)aArrowDirection
{
    CGRect result = [self outerRect:rect arrowDirection:aArrowDirection];
    
    result.origin.x += borderWidth;
    result.origin.y += 0;
    result.size.width -= 2 * borderWidth;
    result.size.height -= borderWidth;
    
    if (navigationBarHeight == 0 || wantsDefaultContentAppearance)
    {
        result.origin.y += borderWidth;
        result.size.height -= borderWidth;
    }
    
    result.origin.x += viewContentInsets.left;
    result.origin.y += viewContentInsets.top;
    result.size.width = result.size.width - viewContentInsets.left - viewContentInsets.right;
    result.size.height = result.size.height - viewContentInsets.top - viewContentInsets.bottom;
    
    if (borderWidth > 0)
    {
        result = CGRectInset(result, -1, -1);
    }
    
    return result;
}

- (CGRect)arrowRect:(CGRect)rect arrowDirection:(PSPTWYPopoverArrowDirection)aArrowDirection
{
    CGRect result = CGRectZero;
    
    if (arrowHeight > 0)
    {
        result.size = CGSizeMake(arrowBase, arrowHeight);
        
        if (aArrowDirection == PSPTWYPopoverArrowDirectionLeft || arrowDirection == PSPTWYPopoverArrowDirectionRight)
        {
            result.size = CGSizeMake(arrowHeight, arrowBase);
        }
        
        CGRect outerRect = [self outerRect:rect arrowDirection:aArrowDirection];
        
        if (aArrowDirection == PSPTWYPopoverArrowDirectionDown)
        {
            result.origin.x = CGRectGetMidX(outerRect) - result.size.width / 2 + arrowOffset;
            result.origin.y = CGRectGetMaxY(outerRect);
        }
        
        if (aArrowDirection == PSPTWYPopoverArrowDirectionUp)
        {
            result.origin.x = CGRectGetMidX(outerRect) - result.size.width / 2 + arrowOffset;
            result.origin.y = CGRectGetMinY(outerRect) - result.size.height;
        }
        
        if (aArrowDirection == PSPTWYPopoverArrowDirectionRight)
        {
            result.origin.x = CGRectGetMaxX(outerRect);
            result.origin.y = CGRectGetMidY(outerRect) - result.size.height / 2 + arrowOffset;
        }
        
        if (aArrowDirection == PSPTWYPopoverArrowDirectionLeft)
        {
            result.origin.x = CGRectGetMinX(outerRect) - result.size.width;
            result.origin.y = CGRectGetMidY(outerRect) - result.size.height / 2 + arrowOffset;
        }
    }
    
    return result;
}

#pragma mark Memory Management

- (void)dealloc
{
    contentView = nil;
    innerView = nil;
    tintColor = nil;
    outerStrokeColor = nil;
    innerStrokeColor = nil;
    fillTopColor = nil;
    fillBottomColor = nil;
    glossShadowColor = nil;
    outerShadowColor = nil;
    innerShadowColor = nil;
    [super dealloc];
}

@end

////////////////////////////////////////////////////////////////////////////

@interface PSPTWYPopoverController () <PSPTWYPopoverOverlayViewDelegate, PSPTWYPopoverBackgroundViewDelegate>
{
    UIViewController        *viewController;
    CGRect                   rect;
    UIView                  *inView;
    PSPTWYPopoverOverlayView    *overlayView;
    PSPTWYPopoverBackgroundView *backgroundView;
    PSPTWYPopoverArrowDirection  permittedArrowDirections;
    BOOL                     animated;
    BOOL                     isListeningNotifications;
    BOOL                     isObserverAdded;
    BOOL                     ignoreOrientation;
    UIBarButtonItem  *barButtonItem;
    
    PSPTWYPopoverAnimationOptions options;
    
    BOOL themeUpdatesEnabled;
    BOOL themeIsUpdating;
}

- (void)dismissPopoverAnimated:(BOOL)aAnimated
                       options:(PSPTWYPopoverAnimationOptions)aAptions
                    completion:(void (^)(void))aCompletion
                  callDelegate:(BOOL)aCallDelegate;

- (PSPTWYPopoverArrowDirection)arrowDirectionForRect:(CGRect)aRect
                                          inView:(UIView*)aView
                                     contentSize:(CGSize)aContentSize
                                     arrowHeight:(float)aArrowHeight
                        permittedArrowDirections:(PSPTWYPopoverArrowDirection)aArrowDirections;

- (CGSize)sizeForRect:(CGRect)aRect
               inView:(UIView *)aView
          arrowHeight:(float)aArrowHeight
       arrowDirection:(PSPTWYPopoverArrowDirection)aArrowDirection;

- (void)registerTheme;
- (void)unregisterTheme;
- (void)updateThemeUI;

- (CGSize)topViewControllerContentSize;

@end

////////////////////////////////////////////////////////////////////////////

#pragma mark
#pragma mark - PSPTWYPopoverController

@implementation PSPTWYPopoverController

@synthesize delegate;
@synthesize passthroughViews;
@synthesize wantsDefaultContentAppearance;
@synthesize popoverVisible;
@synthesize popoverLayoutMargins;
@synthesize popoverContentSize = popoverContentSize_;
@synthesize animationDuration;
@synthesize theme;

static PSPTWYPopoverTheme *defaultTheme_ = nil;

+ (void)setDefaultTheme:(PSPTWYPopoverTheme *)aTheme
{
    defaultTheme_ = aTheme;
    
    @autoreleasepool {
        PSPTWYPopoverBackgroundView *appearance = [PSPTWYPopoverBackgroundView appearance];
        appearance.usesRoundedArrow = aTheme.usesRoundedArrow;
        appearance.dimsBackgroundViewsTintColor = aTheme.dimsBackgroundViewsTintColor;
        appearance.tintColor = aTheme.tintColor;
        appearance.outerStrokeColor = aTheme.outerStrokeColor;
        appearance.innerStrokeColor = aTheme.innerStrokeColor;
        appearance.fillTopColor = aTheme.fillTopColor;
        appearance.fillBottomColor = aTheme.fillBottomColor;
        appearance.glossShadowColor = aTheme.glossShadowColor;
        appearance.glossShadowOffset = aTheme.glossShadowOffset;
        appearance.glossShadowBlurRadius = aTheme.glossShadowBlurRadius;
        appearance.borderWidth = aTheme.borderWidth;
        appearance.arrowBase = aTheme.arrowBase;
        appearance.arrowHeight = aTheme.arrowHeight;
        appearance.outerShadowColor = aTheme.outerShadowColor;
        appearance.outerShadowBlurRadius = aTheme.outerShadowBlurRadius;
        appearance.outerShadowOffset = aTheme.outerShadowOffset;
        appearance.outerCornerRadius = aTheme.outerCornerRadius;
        appearance.minOuterCornerRadius = aTheme.minOuterCornerRadius;
        appearance.innerShadowColor = aTheme.innerShadowColor;
        appearance.innerShadowBlurRadius = aTheme.innerShadowBlurRadius;
        appearance.innerShadowOffset = aTheme.innerShadowOffset;
        appearance.innerCornerRadius = aTheme.innerCornerRadius;
        appearance.viewContentInsets = aTheme.viewContentInsets;
        appearance.overlayColor = aTheme.overlayColor;
    }
}

+ (PSPTWYPopoverTheme *)defaultTheme
{
    return defaultTheme_;
}

+ (void)load
{
    [PSPTWYPopoverController setDefaultTheme:[PSPTWYPopoverTheme theme]];
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        // ignore orientation in iOS8
        ignoreOrientation = (compileUsingIOS8SDK() && [[NSProcessInfo processInfo] respondsToSelector:@selector(operatingSystemVersion)]);
        popoverLayoutMargins = UIEdgeInsetsMake(10, 10, 10, 10);
        animationDuration = WY_POPOVER_DEFAULT_ANIMATION_DURATION;
        
        themeUpdatesEnabled = NO;
        
        [self setTheme:[PSPTWYPopoverController defaultTheme]];
        
        themeIsUpdating = YES;
        
        PSPTWYPopoverBackgroundView *appearance = [PSPTWYPopoverBackgroundView appearance];
        theme.usesRoundedArrow = appearance.usesRoundedArrow;
        theme.dimsBackgroundViewsTintColor = appearance.dimsBackgroundViewsTintColor;
        theme.tintColor = appearance.tintColor;
        theme.outerStrokeColor = appearance.outerStrokeColor;
        theme.innerStrokeColor = appearance.innerStrokeColor;
        theme.fillTopColor = appearance.fillTopColor;
        theme.fillBottomColor = appearance.fillBottomColor;
        theme.glossShadowColor = appearance.glossShadowColor;
        theme.glossShadowOffset = appearance.glossShadowOffset;
        theme.glossShadowBlurRadius = appearance.glossShadowBlurRadius;
        theme.borderWidth = appearance.borderWidth;
        theme.arrowBase = appearance.arrowBase;
        theme.arrowHeight = appearance.arrowHeight;
        theme.outerShadowColor = appearance.outerShadowColor;
        theme.outerShadowBlurRadius = appearance.outerShadowBlurRadius;
        theme.outerShadowOffset = appearance.outerShadowOffset;
        theme.outerCornerRadius = appearance.outerCornerRadius;
        theme.minOuterCornerRadius = appearance.minOuterCornerRadius;
        theme.innerShadowColor = appearance.innerShadowColor;
        theme.innerShadowBlurRadius = appearance.innerShadowBlurRadius;
        theme.innerShadowOffset = appearance.innerShadowOffset;
        theme.innerCornerRadius = appearance.innerCornerRadius;
        theme.viewContentInsets = appearance.viewContentInsets;
        theme.overlayColor = appearance.overlayColor;

        themeIsUpdating = NO;
        themeUpdatesEnabled = YES;
        
        popoverContentSize_ = CGSizeZero;
    }
    
    return self;
}

- (id)initWithContentViewController:(UIViewController *)aViewController
{
    self = [self init];
    
    if (self)
    {
        viewController = aViewController;
    }
    
    return self;
}

- (void)setTheme:(PSPTWYPopoverTheme *)value
{
    [self unregisterTheme];
    theme = value;
    [self registerTheme];
    [self updateThemeUI];
    
    themeIsUpdating = NO;
}

- (void)registerTheme
{
    if (theme == nil) return;
    
    NSArray *keypaths = [theme observableKeypaths];
    for (NSString *keypath in keypaths) {
		[theme addObserver:self forKeyPath:keypath options:NSKeyValueObservingOptionNew context:NULL];
	}
}

- (void)unregisterTheme
{
    if (theme == nil) return;
    
    @try {
        NSArray *keypaths = [theme observableKeypaths];
        for (NSString *keypath in keypaths) {
            [theme removeObserver:self forKeyPath:keypath];
        }
    }
    @catch (NSException * __unused exception) {}
}

- (void)updateThemeUI
{
    if (theme == nil || themeUpdatesEnabled == NO || themeIsUpdating == YES) return;
    
    if (backgroundView != nil) {
        backgroundView.usesRoundedArrow = theme.usesRoundedArrow;
        backgroundView.dimsBackgroundViewsTintColor = theme.dimsBackgroundViewsTintColor;
        backgroundView.tintColor = theme.tintColor;
        backgroundView.outerStrokeColor = theme.outerStrokeColor;
        backgroundView.innerStrokeColor = theme.innerStrokeColor;
        backgroundView.fillTopColor = theme.fillTopColor;
        backgroundView.fillBottomColor = theme.fillBottomColor;
        backgroundView.glossShadowColor = theme.glossShadowColor;
        backgroundView.glossShadowOffset = theme.glossShadowOffset;
        backgroundView.glossShadowBlurRadius = theme.glossShadowBlurRadius;
        backgroundView.borderWidth = theme.borderWidth;
        backgroundView.arrowBase = theme.arrowBase;
        backgroundView.arrowHeight = theme.arrowHeight;
        backgroundView.outerShadowColor = theme.outerShadowColor;
        backgroundView.outerShadowBlurRadius = theme.outerShadowBlurRadius;
        backgroundView.outerShadowOffset = theme.outerShadowOffset;
        backgroundView.outerCornerRadius = theme.outerCornerRadius;
        backgroundView.minOuterCornerRadius = theme.minOuterCornerRadius;
        backgroundView.innerShadowColor = theme.innerShadowColor;
        backgroundView.innerShadowBlurRadius = theme.innerShadowBlurRadius;
        backgroundView.innerShadowOffset = theme.innerShadowOffset;
        backgroundView.innerCornerRadius = theme.innerCornerRadius;
        backgroundView.viewContentInsets = theme.viewContentInsets;
        [backgroundView setNeedsDisplay];
    }
    
    if (overlayView != nil) {
        overlayView.backgroundColor = theme.overlayColor;
    }
    
    [self positionPopover:NO];
    
    [self setPopoverNavigationBarBackgroundImage];
}

- (void)beginThemeUpdates
{
    themeIsUpdating = YES;
}

- (void)endThemeUpdates
{
    themeIsUpdating = NO;
    [self updateThemeUI];
}

/*- (BOOL)isPopoverVisible
{
    BOOL result = (overlayView != nil);
    return result;
}*/

- (UIViewController *)contentViewController
{
    return viewController;
}

- (CGSize)topViewControllerContentSize
{
    CGSize result = CGSizeZero;
    
    UIViewController *topViewController = viewController;
    
    if ([viewController isKindOfClass:[UINavigationController class]] == YES)
    {
        UINavigationController *navigationController = (UINavigationController *)viewController;
        topViewController = [navigationController topViewController];
    }
    
#ifdef WY_BASE_SDK_7_ENABLED
    if ([topViewController respondsToSelector:@selector(preferredContentSize)])
    {
        result = topViewController.preferredContentSize;
    }
#endif
    
    if (CGSizeEqualToSize(result, CGSizeZero))
    {
#pragma clang diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated"
        result = topViewController.contentSizeForViewInPopover;
#pragma clang diagnostic pop
    }
    
    if (CGSizeEqualToSize(result, CGSizeZero))
    {
        CGSize windowSize = [[UIApplication sharedApplication] keyWindow].bounds.size;
        
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        result = CGSizeMake(320, UIDeviceOrientationIsLandscape((UIDeviceOrientation)orientation) ? windowSize.width : windowSize.height);
    }
    
    return result;
}

- (CGSize)popoverContentSize
{
    CGSize result = popoverContentSize_;
    
    if (CGSizeEqualToSize(result, CGSizeZero))
    {
        result = [self topViewControllerContentSize];
    }
    
    return result;
}

- (void)setPopoverContentSize:(CGSize)size
{
    popoverContentSize_ = size;
    [self positionPopover:YES];
}

- (void)setPopoverContentSize:(CGSize)size animated:(BOOL)a
{
    popoverContentSize_ = size;
    [self positionPopover:a];
}

- (void)performWithoutAnimation:(void (^)(void))aBlock
{
    if (aBlock) {
        self.implicitAnimationsDisabled = YES;
        aBlock();
        self.implicitAnimationsDisabled = NO;
    }
}

- (void)presentPopoverFromRect:(CGRect)aRect
                        inView:(UIView *)aView
      permittedArrowDirections:(PSPTWYPopoverArrowDirection)aArrowDirections
                      animated:(BOOL)aAnimated
{
    [self presentPopoverFromRect:aRect
                          inView:aView
        permittedArrowDirections:aArrowDirections
                        animated:aAnimated
                      completion:nil];
}

- (void)presentPopoverFromRect:(CGRect)aRect
                        inView:(UIView *)aView
      permittedArrowDirections:(PSPTWYPopoverArrowDirection)aArrowDirections
                      animated:(BOOL)aAnimated
                    completion:(void (^)(void))completion
{
    [self presentPopoverFromRect:aRect
                          inView:aView
        permittedArrowDirections:aArrowDirections
                        animated:aAnimated
                         options:PSPTWYPopoverAnimationOptionFade
                      completion:completion];
}

- (void)presentPopoverFromRect:(CGRect)aRect
                        inView:(UIView *)aView
      permittedArrowDirections:(PSPTWYPopoverArrowDirection)aArrowDirections
                      animated:(BOOL)aAnimated
                       options:(PSPTWYPopoverAnimationOptions)aOptions
{
    [self presentPopoverFromRect:aRect
                          inView:aView
        permittedArrowDirections:aArrowDirections
                        animated:aAnimated
                         options:aOptions
                      completion:nil];
}

- (void)presentPopoverFromRect:(CGRect)aRect
                        inView:(UIView *)aView
      permittedArrowDirections:(PSPTWYPopoverArrowDirection)aArrowDirections
                      animated:(BOOL)aAnimated
                       options:(PSPTWYPopoverAnimationOptions)aOptions
                    completion:(void (^)(void))completion
{
    NSAssert((aArrowDirections != PSPTWYPopoverArrowDirectionUnknown), @"PSPTWYPopoverArrowDirection must not be UNKNOWN");
    
    rect = aRect;
    inView = aView;
    permittedArrowDirections = aArrowDirections;
    animated = aAnimated;
    options = aOptions;
    
    if (!inView)
    {
        inView = [UIApplication sharedApplication].keyWindow.rootViewController.view;
        if (CGRectIsEmpty(rect))
        {
            rect = CGRectMake((int)inView.bounds.size.width / 2 - 5, (int)inView.bounds.size.height / 2 - 5, 10, 10);
        }
    }
    
    CGSize contentViewSize = self.popoverContentSize;
    
    if (overlayView == nil)
    {
        overlayView = [[PSPTWYPopoverOverlayView alloc] initWithFrame:inView.window.bounds];
        overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        overlayView.autoresizesSubviews = NO;
        overlayView.delegate = self;
        overlayView.passthroughViews = passthroughViews;
        
        backgroundView = [[PSPTWYPopoverBackgroundView alloc] initWithContentSize:contentViewSize];
        backgroundView.appearing = YES;
        
        backgroundView.delegate = self;
        backgroundView.hidden = YES;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:backgroundView action:@selector(tapOut)];
        tap.cancelsTouchesInView = NO;
        [overlayView addGestureRecognizer:tap];
        
        if (self.dismissOnTap)
        {
            tap = [[UITapGestureRecognizer alloc] initWithTarget:backgroundView action:@selector(tapOut)];
            tap.cancelsTouchesInView = NO;
            [backgroundView addGestureRecognizer:tap];
        }
        
        [inView.window addSubview:backgroundView];
        [inView.window insertSubview:overlayView belowSubview:backgroundView];
    }
    
    [self updateThemeUI];
    
   __typeof__(self) weakSelf = self;
    
    void (^completionBlock)(BOOL) = ^(BOOL animated) {
        
        __typeof__(self) strongSelf = weakSelf;
        
        if (strongSelf)
        {
            if (isObserverAdded == NO)
            {
                isObserverAdded = YES;

                if ([strongSelf->viewController respondsToSelector:@selector(preferredContentSize)])
                {
                    [strongSelf->viewController addObserver:self forKeyPath:NSStringFromSelector(@selector(preferredContentSize)) options:0 context:nil];
                }
                else
                {
                    [strongSelf->viewController addObserver:self forKeyPath:NSStringFromSelector(@selector(contentSizeForViewInPopover)) options:0 context:nil];
                }
            }
            
            strongSelf->backgroundView.appearing = NO;
        }
        
        if (completion)
        {
            completion();
        }
        else if (strongSelf && strongSelf->delegate && [strongSelf->delegate respondsToSelector:@selector(popoverControllerDidPresentPopover:)])
        {
            [strongSelf->delegate popoverControllerDidPresentPopover:strongSelf];
        }
        
        
    };
    
    void (^adjustTintDimmed)() = ^() {
#ifdef WY_BASE_SDK_7_ENABLED
        if (backgroundView.dimsBackgroundViewsTintColor && [inView.window respondsToSelector:@selector(setTintAdjustmentMode:)]) {
            for (UIView *subview in inView.window.subviews) {
                if (subview != backgroundView) {
                    [subview setTintAdjustmentMode:UIViewTintAdjustmentModeDimmed];
                }
            }
        }
#endif
    };
    
    backgroundView.hidden = NO;
    
    if (animated)
    {
        if ((options & PSPTWYPopoverAnimationOptionFade) == PSPTWYPopoverAnimationOptionFade)
        {
            overlayView.alpha = 0;
            backgroundView.alpha = 0;
        }
        
        CGAffineTransform endTransform = backgroundView.transform;
        
        if ((options & PSPTWYPopoverAnimationOptionScale) == PSPTWYPopoverAnimationOptionScale)
        {
            CGAffineTransform startTransform = [self transformForArrowDirection:backgroundView.arrowDirection];
            backgroundView.transform = startTransform;
        }
        
        [UIView animateWithDuration:animationDuration animations:^{
            __typeof__(self) strongSelf = weakSelf;
            
            if (strongSelf)
            {
                strongSelf->overlayView.alpha = 1;
                strongSelf->backgroundView.alpha = 1;
                strongSelf->backgroundView.transform = endTransform;
            }
            adjustTintDimmed();
        } completion:^(BOOL finished) {
            completionBlock(YES);
        }];
    }
    else
    {
        adjustTintDimmed();
        completionBlock(NO);
    }
}

- (void)presentPopoverFromBarButtonItem:(UIBarButtonItem *)aItem
               permittedArrowDirections:(PSPTWYPopoverArrowDirection)aArrowDirections
                               animated:(BOOL)aAnimated
{
    [self presentPopoverFromBarButtonItem:aItem
                 permittedArrowDirections:aArrowDirections
                                 animated:aAnimated
                               completion:nil];
}

- (void)presentPopoverFromBarButtonItem:(UIBarButtonItem *)aItem
               permittedArrowDirections:(PSPTWYPopoverArrowDirection)aArrowDirections
                               animated:(BOOL)aAnimated
                             completion:(void (^)(void))completion
{
    [self presentPopoverFromBarButtonItem:aItem
                 permittedArrowDirections:aArrowDirections
                                 animated:aAnimated
                                  options:PSPTWYPopoverAnimationOptionFade
                               completion:completion];
}

- (void)presentPopoverFromBarButtonItem:(UIBarButtonItem *)aItem
               permittedArrowDirections:(PSPTWYPopoverArrowDirection)aArrowDirections
                               animated:(BOOL)aAnimated
                                options:(PSPTWYPopoverAnimationOptions)aOptions
{
    [self presentPopoverFromBarButtonItem:aItem
                 permittedArrowDirections:aArrowDirections
                                 animated:aAnimated
                                  options:aOptions
                               completion:nil];
}

- (void)presentPopoverFromBarButtonItem:(UIBarButtonItem *)aItem
               permittedArrowDirections:(PSPTWYPopoverArrowDirection)aArrowDirections
                               animated:(BOOL)aAnimated
                                options:(PSPTWYPopoverAnimationOptions)aOptions
                             completion:(void (^)(void))completion
{
    barButtonItem = aItem;
    UIView *itemView = [barButtonItem valueForKey:@"view"];
    aArrowDirections = PSPTWYPopoverArrowDirectionDown | PSPTWYPopoverArrowDirectionUp;
    [self presentPopoverFromRect:itemView.bounds
                          inView:itemView
        permittedArrowDirections:aArrowDirections
                        animated:aAnimated
                         options:aOptions
                      completion:completion];
}

- (void)presentPopoverAsDialogAnimated:(BOOL)aAnimated
{
    [self presentPopoverAsDialogAnimated:aAnimated
                              completion:nil];
}

- (void)presentPopoverAsDialogAnimated:(BOOL)aAnimated
                            completion:(void (^)(void))completion
{
    [self presentPopoverAsDialogAnimated:aAnimated
                                 options:PSPTWYPopoverAnimationOptionFade
                              completion:completion];
}

- (void)presentPopoverAsDialogAnimated:(BOOL)aAnimated
                               options:(PSPTWYPopoverAnimationOptions)aOptions
{
    [self presentPopoverAsDialogAnimated:aAnimated
                                 options:aOptions
                              completion:nil];
}

- (void)presentPopoverAsDialogAnimated:(BOOL)aAnimated
                               options:(PSPTWYPopoverAnimationOptions)aOptions
                            completion:(void (^)(void))completion
{
    [self presentPopoverFromRect:CGRectZero
                          inView:nil
        permittedArrowDirections:PSPTWYPopoverArrowDirectionNone
                        animated:aAnimated
                         options:aOptions
                      completion:completion];
}

- (CGAffineTransform)transformForArrowDirection:(PSPTWYPopoverArrowDirection)arrowDirection
{
    CGAffineTransform transform = backgroundView.transform;
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];

    CGSize containerViewSize = backgroundView.frame.size;
    
    if (backgroundView.arrowHeight > 0)
    {
        if (UIDeviceOrientationIsLandscape((UIDeviceOrientation)orientation)) {
            containerViewSize.width = backgroundView.frame.size.height;
            containerViewSize.height = backgroundView.frame.size.width;
        }
        
        if (arrowDirection == PSPTWYPopoverArrowDirectionDown)
        {
            transform = CGAffineTransformTranslate(transform, backgroundView.arrowOffset, containerViewSize.height / 2);
        }
        
        if (arrowDirection == PSPTWYPopoverArrowDirectionUp)
        {
            transform = CGAffineTransformTranslate(transform, backgroundView.arrowOffset, -containerViewSize.height / 2);
        }
        
        if (arrowDirection == PSPTWYPopoverArrowDirectionRight)
        {
            transform = CGAffineTransformTranslate(transform, containerViewSize.width / 2, backgroundView.arrowOffset);
        }
        
        if (arrowDirection == PSPTWYPopoverArrowDirectionLeft)
        {
            transform = CGAffineTransformTranslate(transform, -containerViewSize.width / 2, backgroundView.arrowOffset);
        }
    }
    
    transform = CGAffineTransformScale(transform, 0.01, 0.01);
    
    return transform;
}

- (void)setPopoverNavigationBarBackgroundImage
{
    if ([viewController isKindOfClass:[UINavigationController class]] == YES)
    {
        UINavigationController *navigationController = (UINavigationController *)viewController;
        
        if ([navigationController respondsToSelector:@selector(setEdgesForExtendedLayout:)])
        {
            UIViewController *topViewController = [navigationController topViewController];
            [topViewController setEdgesForExtendedLayout:UIRectEdgeNone];
        }
        
    }
    
    viewController.view.clipsToBounds = YES;
    
    if (backgroundView.borderWidth == 0)
    {
        viewController.view.layer.cornerRadius = backgroundView.outerCornerRadius;
    }
}

- (void)positionPopover:(BOOL)aAnimated
{
    CGRect savedContainerFrame = backgroundView.frame;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGSize contentViewSize = self.popoverContentSize;
    CGSize minContainerSize = WY_POPOVER_MIN_SIZE;
    
    CGRect viewFrame;
    CGRect containerFrame = CGRectZero;
    float minX, maxX, minY, maxY, offset = 0;
    CGSize containerViewSize = CGSizeZero;
    
    float overlayWidth;
    float overlayHeight;
    
    if (ignoreOrientation)
    {
        overlayWidth = overlayView.window.frame.size.width;
        overlayHeight = overlayView.window.frame.size.height;
    }
    else
    {
        overlayWidth = UIInterfaceOrientationIsPortrait(orientation) ? overlayView.bounds.size.width : overlayView.bounds.size.height;
        overlayHeight = UIInterfaceOrientationIsPortrait(orientation) ? overlayView.bounds.size.height : overlayView.bounds.size.width;

    }
    
    
    PSPTWYPopoverArrowDirection arrowDirection = permittedArrowDirections;
    
    overlayView.bounds = inView.window.bounds;
    backgroundView.transform = CGAffineTransformIdentity;
    
    viewFrame = [inView convertRect:rect toView:nil];
    
    viewFrame = WYRectInWindowBounds(viewFrame, orientation);
    
    minX = popoverLayoutMargins.left;
    maxX = overlayWidth - popoverLayoutMargins.right;
    minY = WYStatusBarHeight() + popoverLayoutMargins.top;
    maxY = overlayHeight - popoverLayoutMargins.bottom;
    
    // Which direction ?
    //
    arrowDirection = [self arrowDirectionForRect:rect
                                          inView:inView
                                     contentSize:contentViewSize
                                     arrowHeight:backgroundView.arrowHeight
                        permittedArrowDirections:arrowDirection];
    
    // Position of the popover
    //
    
    minX -= backgroundView.outerShadowInsets.left;
    maxX += backgroundView.outerShadowInsets.right;
    minY -= backgroundView.outerShadowInsets.top;
    maxY += backgroundView.outerShadowInsets.bottom;
    
    if (arrowDirection == PSPTWYPopoverArrowDirectionDown)
    {
        backgroundView.arrowDirection = PSPTWYPopoverArrowDirectionDown;
        containerViewSize = [backgroundView sizeThatFits:contentViewSize];
        
        containerFrame = CGRectZero;
        containerFrame.size = containerViewSize;
        containerFrame.size.width = MIN(maxX - minX, containerFrame.size.width);
        containerFrame.size.height = MIN(maxY - minY, containerFrame.size.height);
        
        backgroundView.frame = CGRectIntegral(containerFrame);
        
        backgroundView.center = CGPointMake(viewFrame.origin.x + viewFrame.size.width / 2, viewFrame.origin.y + viewFrame.size.height / 2);
        
        containerFrame = backgroundView.frame;
        
        offset = 0;
        
        if (containerFrame.origin.x < minX)
        {
            offset = minX - containerFrame.origin.x;
            containerFrame.origin.x = minX;
            offset = -offset;
        }
        else if (containerFrame.origin.x + containerFrame.size.width > maxX)
        {
            offset = (backgroundView.frame.origin.x + backgroundView.frame.size.width) - maxX;
            containerFrame.origin.x -= offset;
        }
        
        backgroundView.arrowOffset = offset;
        offset = backgroundView.frame.size.height / 2 + viewFrame.size.height / 2 - backgroundView.outerShadowInsets.bottom;
        
        containerFrame.origin.y -= offset;
        
        if (containerFrame.origin.y < minY)
        {
            offset = minY - containerFrame.origin.y;
            containerFrame.size.height -= offset;
            
            if (containerFrame.size.height < minContainerSize.height)
            {
                // popover is overflowing
                offset -= (minContainerSize.height - containerFrame.size.height);
                containerFrame.size.height = minContainerSize.height;
            }
            
            containerFrame.origin.y += offset;
        }
    }
    
    if (arrowDirection == PSPTWYPopoverArrowDirectionUp)
    {
        backgroundView.arrowDirection = PSPTWYPopoverArrowDirectionUp;
        containerViewSize = [backgroundView sizeThatFits:contentViewSize];
        
        containerFrame = CGRectZero;
        containerFrame.size = containerViewSize;
        containerFrame.size.width = MIN(maxX - minX, containerFrame.size.width);
        containerFrame.size.height = MIN(maxY - minY, containerFrame.size.height);
        
        backgroundView.frame = containerFrame;
        
        backgroundView.center = CGPointMake(viewFrame.origin.x + viewFrame.size.width / 2, viewFrame.origin.y + viewFrame.size.height / 2);
        
        containerFrame = backgroundView.frame;
        
        offset = 0;
        
        if (containerFrame.origin.x < minX)
        {
            offset = minX - containerFrame.origin.x;
            containerFrame.origin.x = minX;
            offset = -offset;
        }
        else if (containerFrame.origin.x + containerFrame.size.width > maxX)
        {
            offset = (backgroundView.frame.origin.x + backgroundView.frame.size.width) - maxX;
            containerFrame.origin.x -= offset;
        }
        
        backgroundView.arrowOffset = offset;
        offset = backgroundView.frame.size.height / 2 + viewFrame.size.height / 2 - backgroundView.outerShadowInsets.top;
        
        containerFrame.origin.y += offset;
        
        if (containerFrame.origin.y + containerFrame.size.height > maxY)
        {
            offset = (containerFrame.origin.y + containerFrame.size.height) - maxY;
            containerFrame.size.height -= offset;
            
            if (containerFrame.size.height < minContainerSize.height)
            {
                // popover is overflowing
                containerFrame.size.height = minContainerSize.height;
            }
        }
    }
    
    if (arrowDirection == PSPTWYPopoverArrowDirectionRight)
    {
        backgroundView.arrowDirection = PSPTWYPopoverArrowDirectionRight;
        containerViewSize = [backgroundView sizeThatFits:contentViewSize];
        
        containerFrame = CGRectZero;
        containerFrame.size = containerViewSize;
        containerFrame.size.width = MIN(maxX - minX, containerFrame.size.width);
        containerFrame.size.height = MIN(maxY - minY, containerFrame.size.height);
        
        backgroundView.frame = CGRectIntegral(containerFrame);
        
        backgroundView.center = CGPointMake(viewFrame.origin.x + viewFrame.size.width / 2, viewFrame.origin.y + viewFrame.size.height / 2);
        
        containerFrame = backgroundView.frame;
        
        offset = backgroundView.frame.size.width / 2 + viewFrame.size.width / 2 - backgroundView.outerShadowInsets.right;
        
        containerFrame.origin.x -= offset;
        
        if (containerFrame.origin.x < minX)
        {
            offset = minX - containerFrame.origin.x;
            containerFrame.size.width -= offset;
            
            if (containerFrame.size.width < minContainerSize.width)
            {
                // popover is overflowing
                offset -= (minContainerSize.width - containerFrame.size.width);
                containerFrame.size.width = minContainerSize.width;
            }
            
            containerFrame.origin.x += offset;
        }
        
        offset = 0;
        
        if (containerFrame.origin.y < minY)
        {
            offset = minY - containerFrame.origin.y;
            containerFrame.origin.y = minY;
            offset = -offset;
        }
        else if (containerFrame.origin.y + containerFrame.size.height > maxY)
        {
            offset = (backgroundView.frame.origin.y + backgroundView.frame.size.height) - maxY;
            containerFrame.origin.y -= offset;
        }
        
        backgroundView.arrowOffset = offset;
    }
    
    if (arrowDirection == PSPTWYPopoverArrowDirectionLeft)
    {
        backgroundView.arrowDirection = PSPTWYPopoverArrowDirectionLeft;
        containerViewSize = [backgroundView sizeThatFits:contentViewSize];
        
        containerFrame = CGRectZero;
        containerFrame.size = containerViewSize;
        containerFrame.size.width = MIN(maxX - minX, containerFrame.size.width);
        containerFrame.size.height = MIN(maxY - minY, containerFrame.size.height);
        backgroundView.frame = containerFrame;
        
        backgroundView.center = CGPointMake(viewFrame.origin.x + viewFrame.size.width / 2, viewFrame.origin.y + viewFrame.size.height / 2);
        
        containerFrame = CGRectIntegral(backgroundView.frame);
        
        offset = backgroundView.frame.size.width / 2 + viewFrame.size.width / 2 - backgroundView.outerShadowInsets.left;
        
        containerFrame.origin.x += offset;
        
        if (containerFrame.origin.x + containerFrame.size.width > maxX)
        {
            offset = (containerFrame.origin.x + containerFrame.size.width) - maxX;
            containerFrame.size.width -= offset;
            
            if (containerFrame.size.width < minContainerSize.width)
            {
                // popover is overflowing
                containerFrame.size.width = minContainerSize.width;
            }
        }
        
        offset = 0;
        
        if (containerFrame.origin.y < minY)
        {
            offset = minY - containerFrame.origin.y;
            containerFrame.origin.y = minY;
            offset = -offset;
        }
        else if (containerFrame.origin.y + containerFrame.size.height > maxY)
        {
            offset = (backgroundView.frame.origin.y + backgroundView.frame.size.height) - maxY;
            containerFrame.origin.y -= offset;
        }
        
        backgroundView.arrowOffset = offset;
    }
    
    if (arrowDirection == PSPTWYPopoverArrowDirectionNone)
    {
        backgroundView.arrowDirection = PSPTWYPopoverArrowDirectionNone;
        containerViewSize = [backgroundView sizeThatFits:contentViewSize];
        
        containerFrame = CGRectZero;
        containerFrame.size = containerViewSize;
        containerFrame.size.width = MIN(maxX - minX, containerFrame.size.width);
        containerFrame.size.height = MIN(maxY - minY, containerFrame.size.height);
        backgroundView.frame = CGRectIntegral(containerFrame);
        
        backgroundView.center = CGPointMake(minX + (maxX - minX) / 2, minY + (maxY - minY) / 2);
        
        containerFrame = backgroundView.frame;
        
        backgroundView.arrowOffset = offset;
    }
    
    containerFrame = CGRectIntegral(containerFrame);
    
    backgroundView.frame = containerFrame;
    
    backgroundView.wantsDefaultContentAppearance = wantsDefaultContentAppearance;
    
    [backgroundView setViewController:viewController];
    
    CGPoint containerOrigin = containerFrame.origin;
    
    backgroundView.transform = CGAffineTransformMakeRotation(WYInterfaceOrientationAngleOfOrientation(orientation));
    
    containerFrame = backgroundView.frame;
    
    containerFrame.origin = WYPointRelativeToOrientation(containerOrigin, containerFrame.size, orientation);

    if (aAnimated == YES && !self.implicitAnimationsDisabled) {
        backgroundView.frame = savedContainerFrame;
        __typeof__(self) weakSelf = self;
        [UIView animateWithDuration:0.10f animations:^{
            __typeof__(self) strongSelf = weakSelf;
            strongSelf->backgroundView.frame = containerFrame;
        }];
    } else {
        backgroundView.frame = containerFrame;
    }
    
    [backgroundView setNeedsDisplay];
}

- (void)dismissPopoverAnimated:(BOOL)aAnimated
{
    [self dismissPopoverAnimated:aAnimated
                         options:options
                      completion:nil];
}

- (void)dismissPopoverAnimated:(BOOL)aAnimated
                    completion:(void (^)(void))completion
{
    [self dismissPopoverAnimated:aAnimated
                         options:options
                      completion:completion];
}

- (void)dismissPopoverAnimated:(BOOL)aAnimated
                       options:(PSPTWYPopoverAnimationOptions)aOptions
{
    [self dismissPopoverAnimated:aAnimated
                         options:aOptions
                      completion:nil];
}

- (void)dismissPopoverAnimated:(BOOL)aAnimated
                       options:(PSPTWYPopoverAnimationOptions)aOptions
                    completion:(void (^)(void))completion
{
    [self dismissPopoverAnimated:aAnimated
                         options:aOptions
                      completion:completion
                    callDelegate:NO];
}

- (void)dismissPopoverAnimated:(BOOL)aAnimated
                       options:(PSPTWYPopoverAnimationOptions)aOptions
                    completion:(void (^)(void))completion
                  callDelegate:(BOOL)callDelegate
{
    float duration = self.animationDuration;
    PSPTWYPopoverAnimationOptions style = aOptions;
    
    __typeof__(self) weakSelf = self;
    
    
    void (^adjustTintAutomatic)() = ^() {
#ifdef WY_BASE_SDK_7_ENABLED
        if ([inView.window respondsToSelector:@selector(setTintAdjustmentMode:)]) {
            for (UIView *subview in inView.window.subviews) {
                if (subview != backgroundView) {
                    [subview setTintAdjustmentMode:UIViewTintAdjustmentModeAutomatic];
                }
            }
        }
#endif
    };
    
    void (^completionBlock)() = ^() {
        
        __typeof__(self) strongSelf = weakSelf;
        
        if (strongSelf) {
            [strongSelf->backgroundView removeFromSuperview];
            
            strongSelf->backgroundView = nil;
            
            [strongSelf->overlayView removeFromSuperview];
            strongSelf->overlayView = nil;
        }
        
        if (completion)
        {
            completion();
        }
        else if (callDelegate && strongSelf && strongSelf->delegate && [strongSelf->delegate respondsToSelector:@selector(popoverControllerDidDismissPopover:)])
        {
            [strongSelf->delegate popoverControllerDidDismissPopover:strongSelf];
        }
        
        if (self.dismissCompletionBlock)
        {
            self.dismissCompletionBlock(strongSelf);
        }
    };

    @try {
        if (isObserverAdded == YES)
        {
            isObserverAdded = NO;
            
            if ([viewController respondsToSelector:@selector(preferredContentSize)]) {
                [viewController removeObserver:self forKeyPath:NSStringFromSelector(@selector(preferredContentSize))];
            } else {
                [viewController removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentSizeForViewInPopover))];
            }
        }
    }
    @catch (NSException * __unused exception) {}
    
    if (aAnimated && !self.implicitAnimationsDisabled)
    {
        [UIView animateWithDuration:duration animations:^{
            __typeof__(self) strongSelf = weakSelf;
            
            if (strongSelf)
            {
                if ((style & PSPTWYPopoverAnimationOptionFade) == PSPTWYPopoverAnimationOptionFade)
                {
                    strongSelf->backgroundView.alpha = 0;
                }
                
                if ((style & PSPTWYPopoverAnimationOptionScale) == PSPTWYPopoverAnimationOptionScale)
                {
                    CGAffineTransform endTransform = [self transformForArrowDirection:strongSelf->backgroundView.arrowDirection];
                    strongSelf->backgroundView.transform = endTransform;
                }
                strongSelf->overlayView.alpha = 0;
            }
            adjustTintAutomatic();
        } completion:^(BOOL finished) {
            completionBlock();
        }];
    }
    else
    {
        adjustTintAutomatic();
        completionBlock();
    }
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == viewController)
    {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(preferredContentSize))]
            || [keyPath isEqualToString:NSStringFromSelector(@selector(contentSizeForViewInPopover))])
        {
            CGSize contentSize = [self topViewControllerContentSize];
            [self setPopoverContentSize:contentSize];
        }
    }
    else if (object == theme)
    {
        [self updateThemeUI];
    }
}

#pragma mark PSPTWYPopoverOverlayViewDelegate

- (void)popoverOverlayViewDidTouch:(PSPTWYPopoverOverlayView *)aOverlayView
{
    BOOL shouldDismiss = !viewController.modalInPopover;
    
    if (shouldDismiss && delegate && [delegate respondsToSelector:@selector(popoverControllerShouldDismissPopover:)])
    {
        shouldDismiss = [delegate popoverControllerShouldDismissPopover:self];
    }
    
    if (shouldDismiss)
    {
        [self dismissPopoverAnimated:animated options:options completion:nil callDelegate:YES];
    }
}

#pragma mark PSPTWYPopoverBackgroundViewDelegate

- (void)popoverBackgroundViewDidTouchOutside:(PSPTWYPopoverBackgroundView *)aBackgroundView
{
    [self popoverOverlayViewDidTouch:nil];
}

#pragma mark Private

- (PSPTWYPopoverArrowDirection)arrowDirectionForRect:(CGRect)aRect
                                          inView:(UIView *)aView
                                     contentSize:(CGSize)contentSize
                                     arrowHeight:(float)arrowHeight
                        permittedArrowDirections:(PSPTWYPopoverArrowDirection)arrowDirections
{
    PSPTWYPopoverArrowDirection arrowDirection = PSPTWYPopoverArrowDirectionUnknown;
    
    NSMutableArray *areas = [NSMutableArray arrayWithCapacity:0];
    PSPTWYPopoverArea *area;
    
    if ((arrowDirections & PSPTWYPopoverArrowDirectionDown) == PSPTWYPopoverArrowDirectionDown)
    {
        area = [[PSPTWYPopoverArea alloc] init];
        area.areaSize = [self sizeForRect:aRect inView:aView arrowHeight:arrowHeight arrowDirection:PSPTWYPopoverArrowDirectionDown];
        area.arrowDirection = PSPTWYPopoverArrowDirectionDown;
        [areas addObject:area];
    }
    
    if ((arrowDirections & PSPTWYPopoverArrowDirectionUp) == PSPTWYPopoverArrowDirectionUp)
    {
        area = [[PSPTWYPopoverArea alloc] init];
        area.areaSize = [self sizeForRect:aRect inView:aView arrowHeight:arrowHeight arrowDirection:PSPTWYPopoverArrowDirectionUp];
        area.arrowDirection = PSPTWYPopoverArrowDirectionUp;
        [areas addObject:area];
    }
    
    if ((arrowDirections & PSPTWYPopoverArrowDirectionLeft) == PSPTWYPopoverArrowDirectionLeft)
    {
        area = [[PSPTWYPopoverArea alloc] init];
        area.areaSize = [self sizeForRect:aRect inView:aView arrowHeight:arrowHeight arrowDirection:PSPTWYPopoverArrowDirectionLeft];
        area.arrowDirection = PSPTWYPopoverArrowDirectionLeft;
        [areas addObject:area];
    }
    
    if ((arrowDirections & PSPTWYPopoverArrowDirectionRight) == PSPTWYPopoverArrowDirectionRight)
    {
        area = [[PSPTWYPopoverArea alloc] init];
        area.areaSize = [self sizeForRect:aRect inView:aView arrowHeight:arrowHeight arrowDirection:PSPTWYPopoverArrowDirectionRight];
        area.arrowDirection = PSPTWYPopoverArrowDirectionRight;
        [areas addObject:area];
    }
    
    if ((arrowDirections & PSPTWYPopoverArrowDirectionNone) == PSPTWYPopoverArrowDirectionNone)
    {
        area = [[PSPTWYPopoverArea alloc] init];
        area.areaSize = [self sizeForRect:aRect inView:aView arrowHeight:arrowHeight arrowDirection:PSPTWYPopoverArrowDirectionNone];
        area.arrowDirection = PSPTWYPopoverArrowDirectionNone;
        [areas addObject:area];
    }
    
    if ([areas count] > 1)
    {
        NSIndexSet* indexes = [areas indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            PSPTWYPopoverArea* popoverArea = (PSPTWYPopoverArea*)obj;
            
            BOOL result = (popoverArea.areaSize.width > 0 && popoverArea.areaSize.height > 0);
            
            return result;
        }];
        
        areas = [NSMutableArray arrayWithArray:[areas objectsAtIndexes:indexes]];
    }
    
    [areas sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        PSPTWYPopoverArea *area1 = (PSPTWYPopoverArea *)obj1;
        PSPTWYPopoverArea *area2 = (PSPTWYPopoverArea *)obj2;
        
        float val1 = area1.value;
        float val2 = area2.value;
        
        NSComparisonResult result = NSOrderedSame;
        
        if (val1 > val2)
        {
            result = NSOrderedAscending;
        }
        else if (val1 < val2)
        {
            result = NSOrderedDescending;
        }
        
        return result;
    }];
    
    for (NSUInteger i = 0; i < [areas count]; i++)
    {
        PSPTWYPopoverArea *popoverArea = (PSPTWYPopoverArea *)[areas objectAtIndex:i];
        
        if (popoverArea.areaSize.width >= contentSize.width)
        {
            arrowDirection = popoverArea.arrowDirection;
            break;
        }
    }
    
    if (arrowDirection == PSPTWYPopoverArrowDirectionUnknown)
    {
        if ([areas count] > 0)
        {
            arrowDirection = ((PSPTWYPopoverArea *)[areas objectAtIndex:0]).arrowDirection;
        }
        else
        {
            if ((arrowDirections & PSPTWYPopoverArrowDirectionDown) == PSPTWYPopoverArrowDirectionDown)
            {
                arrowDirection = PSPTWYPopoverArrowDirectionDown;
            }
            else if ((arrowDirections & PSPTWYPopoverArrowDirectionUp) == PSPTWYPopoverArrowDirectionUp)
            {
                arrowDirection = PSPTWYPopoverArrowDirectionUp;
            }
            else if ((arrowDirections & PSPTWYPopoverArrowDirectionLeft) == PSPTWYPopoverArrowDirectionLeft)
            {
                arrowDirection = PSPTWYPopoverArrowDirectionLeft;
            }
            else
            {
                arrowDirection = PSPTWYPopoverArrowDirectionRight;
            }
        }
    }
    
    return arrowDirection;
}

- (CGSize)sizeForRect:(CGRect)aRect
               inView:(UIView *)aView
          arrowHeight:(float)arrowHeight
       arrowDirection:(PSPTWYPopoverArrowDirection)arrowDirection
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    CGRect viewFrame = [aView convertRect:aRect toView:nil];
    viewFrame = WYRectInWindowBounds(viewFrame, orientation);
    
    float minX, maxX, minY, maxY = 0;
    
    float overlayWidth = UIInterfaceOrientationIsPortrait(orientation) ? overlayView.bounds.size.width : overlayView.bounds.size.height;
    
    float overlayHeight = UIInterfaceOrientationIsPortrait(orientation) ? overlayView.bounds.size.height : overlayView.bounds.size.width;
    
    minX = popoverLayoutMargins.left;
    maxX = overlayWidth - popoverLayoutMargins.right;
    minY = WYStatusBarHeight() + popoverLayoutMargins.top;
    maxY = overlayHeight - popoverLayoutMargins.bottom;
    
    CGSize result = CGSizeZero;
    
    if (arrowDirection == PSPTWYPopoverArrowDirectionLeft)
    {
        result.width = maxX - (viewFrame.origin.x + viewFrame.size.width);
        result.width -= arrowHeight;
        result.height = maxY - minY;
    }
    else if (arrowDirection == PSPTWYPopoverArrowDirectionRight)
    {
        result.width = viewFrame.origin.x - minX;
        result.width -= arrowHeight;
        result.height = maxY - minY;
    }
    else if (arrowDirection == PSPTWYPopoverArrowDirectionDown)
    {
        result.width = maxX - minX;
        result.height = viewFrame.origin.y - minY;
        result.height -= arrowHeight;
    }
    else if (arrowDirection == PSPTWYPopoverArrowDirectionUp)
    {
        result.width = maxX - minX;
        result.height = maxY - (viewFrame.origin.y + viewFrame.size.height);
        result.height -= arrowHeight;
    }
    else if (arrowDirection == PSPTWYPopoverArrowDirectionNone)
    {
        result.width = maxX - minX;
        result.height = maxY - minY;
    }
    
    return result;
}

#pragma mark Inline functions

static BOOL compileUsingIOS8SDK() {
    
    #if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
        return YES;
    #endif
    
    return NO;
}

__unused static NSString* WYStringFromOrientation(NSInteger orientation) {
    NSString *result = @"Unknown";
    
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            result = @"Portrait";
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            result = @"Portrait UpsideDown";
            break;
        case UIInterfaceOrientationLandscapeLeft:
            result = @"Landscape Left";
            break;
        case UIInterfaceOrientationLandscapeRight:
            result = @"Landscape Right";
            break;
        default:
            break;
    }
    
    return result;
}

static float WYStatusBarHeight() {

    if (compileUsingIOS8SDK() && [[NSProcessInfo processInfo] respondsToSelector:@selector(operatingSystemVersion)]) {
        CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
        return statusBarFrame.size.height;
    } else {
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];

        float statusBarHeight = 0;
        {
            CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
            statusBarHeight = statusBarFrame.size.height;

            if (UIDeviceOrientationIsLandscape((UIDeviceOrientation)orientation))
            {
                statusBarHeight = statusBarFrame.size.width;
            }
        }

        return statusBarHeight;
    }
}

static float WYInterfaceOrientationAngleOfOrientation(UIInterfaceOrientation orientation)
{
    float angle;
    // no transformation needed in iOS 8
    if (compileUsingIOS8SDK() && [[NSProcessInfo processInfo] respondsToSelector:@selector(operatingSystemVersion)]) {
        angle = 0.0;
    } else {
        switch (orientation)
        {
            case UIInterfaceOrientationPortraitUpsideDown:
                angle = M_PI;
                break;
            case UIInterfaceOrientationLandscapeLeft:
                angle = -M_PI_2;
                break;
            case UIInterfaceOrientationLandscapeRight:
                angle = M_PI_2;
                break;
            default:
                angle = 0.0;
                break;
        }
    }
    
    return angle;
}

static CGRect WYRectInWindowBounds(CGRect rect, UIInterfaceOrientation orientation) {
    
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    
    float windowWidth = keyWindow.bounds.size.width;
    float windowHeight = keyWindow.bounds.size.height;
    
    CGRect result = rect;
    if (!(compileUsingIOS8SDK() && [[NSProcessInfo processInfo] respondsToSelector:@selector(operatingSystemVersion)])) {
        
        if (orientation == UIInterfaceOrientationLandscapeRight) {
            
            result.origin.x = rect.origin.y;
            result.origin.y = windowWidth - rect.origin.x - rect.size.width;
            result.size.width = rect.size.height;
            result.size.height = rect.size.width;
        }
        
        if (orientation == UIInterfaceOrientationLandscapeLeft) {
            
            result.origin.x = windowHeight - rect.origin.y - rect.size.height;
            result.origin.y = rect.origin.x;
            result.size.width = rect.size.height;
            result.size.height = rect.size.width;
        }
        
        if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
            
            result.origin.x = windowWidth - rect.origin.x - rect.size.width;
            result.origin.y = windowHeight - rect.origin.y - rect.size.height;
        }
    }
    
    return result;
}

static CGPoint WYPointRelativeToOrientation(CGPoint origin, CGSize size, UIInterfaceOrientation orientation) {
    
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    
    float windowWidth = keyWindow.bounds.size.width;
    float windowHeight = keyWindow.bounds.size.height;
    
    CGPoint result = origin;
    if (!(compileUsingIOS8SDK() && [[NSProcessInfo processInfo] respondsToSelector:@selector(operatingSystemVersion)])) {
        
        if (orientation == UIInterfaceOrientationLandscapeRight) {
            result.x = windowWidth - origin.y - size.width;
            result.y = origin.x;
        }
        
        if (orientation == UIInterfaceOrientationLandscapeLeft) {
            result.x = origin.y;
            result.y = windowHeight - origin.x - size.height;
        }
        
        if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
            result.x = windowWidth - origin.x - size.width;
            result.y = windowHeight - origin.y - size.height;
        }
    }
    
    return result;
}

#pragma mark Memory management

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [backgroundView removeFromSuperview];
    [backgroundView setDelegate:nil];
    
    [overlayView removeFromSuperview];
    [overlayView setDelegate:nil];
    @try {
        if (isObserverAdded == YES) {
            isObserverAdded = NO;
            
            if ([viewController respondsToSelector:@selector(preferredContentSize)]) {
                [viewController removeObserver:self forKeyPath:NSStringFromSelector(@selector(preferredContentSize))];
            } else {
                [viewController removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentSizeForViewInPopover))];
            }
        }
    }
    @catch (NSException *exception) {
    }
    @finally {
        viewController = nil;
    }

    [self unregisterTheme];
  
    barButtonItem = nil;
    passthroughViews = nil;
    inView = nil;
    overlayView = nil;
    backgroundView = nil;
    
    theme = nil;
    [super dealloc];
}

@end

