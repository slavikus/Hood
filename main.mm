#import <Foundation/Foundation.h>
#import "MobileEnhancer/MobileEnhancer.h"
#import "RipHoodController.h"
#import "SDK/objc-patch.h"
#import <objc/message.h>

static RipHoodController* sRipHood = nil;

static void RiP_CreateHoodController();
static void RiP_InvokeRipHood();

//typedef void (*SBStatusBar_mouseDraggedProcPtr)(UIControl* obj, SEL sel, void* event);
//static void RiP_SBStatusBar_mouseDragged(UIControl* obj, SEL sel, void* event);
//static SBStatusBar_mouseDraggedProcPtr gSBStatusBar_mouseDragged = nil;

// - (void)touchesEnded:(id)fp8 withEvent:(id)fp12;
typedef void (*SBStatusBar_touchesEnded_withEventProcPtr)(id obj, SEL sel, id touches, id event);
static void Ripdev_SBStatusBar_touchesEnded_withEvent(id obj, SEL sel, id touches, id event);
static SBStatusBar_touchesEnded_withEventProcPtr gSBStatusBar_touchesEnded_withEvent = nil;

// -(void)[SBAwayController frontLocked:animate:automatically:](char, char, char):
typedef void (*SBAwayController_frontLocked_animate_automaticallyProcPtr)(id obj, SEL sel, BOOL frontLocked, BOOL animate, BOOL automatically);
static SBAwayController_frontLocked_animate_automaticallyProcPtr gSBAwayController_frontLocked_animate_automatically = NULL;
static void RiP_SBAwayController_frontLocked_animate_automatically(id obj, SEL sel, BOOL frontLocked, BOOL animate, BOOL automatically);

@interface NSObject (RiPSillySelectors__Hood)
- (BOOL)isLocked;
- (int)UIOrientation;
- (void)setRotationBy:(float)degrees;
@end

static void observer_callback(CFNotificationCenterRef center, void * observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);

int MENModuleMain(CFBundleRef inModuleBundle, CFBundleRef inApplicationBundle, int inArgc, char ** inArgv)
{
	NSAutoreleasePool * innerPool = [[NSAutoreleasePool alloc] init];
	
	gSBStatusBar_touchesEnded_withEvent = (SBStatusBar_touchesEnded_withEventProcPtr)_OBJCInstanceMetodPatch(@"SBStatusBar", @"touchesMoved:withEvent:", (const void*)Ripdev_SBStatusBar_touchesEnded_withEvent);
	gSBAwayController_frontLocked_animate_automatically = (SBAwayController_frontLocked_animate_automaticallyProcPtr)_OBJCInstanceMetodPatch(@"SBAwayController", @"frontLocked:animate:automatically:", (const void*)RiP_SBAwayController_frontLocked_animate_automatically);
	
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, observer_callback, CFSTR("com.ripdev.hood.pepyaka"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	
	[innerPool release];
	
	return 0;
}

static void observer_callback(CFNotificationCenterRef center, void * observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	[sRipHood _setupFromPrefs];
}

#pragma mark -

static void Ripdev_SBStatusBar_touchesEnded_withEvent(id obj, SEL sel, id touches, id event)
{
	Class sbAwayController = NSClassFromString(@"SBAwayController");
	if (sbAwayController)
	{
		BOOL locked = NO;
		
		id contr = objc_msgSend(sbAwayController, NSSelectorFromString(@"sharedAwayController"));
		
		if (contr)
		{
			locked = [contr isLocked];
		}
		
		if (!locked)
			RiP_InvokeRipHood();
	}
	
	gSBStatusBar_touchesEnded_withEvent(obj, sel, touches, event);
}

#pragma mark -

static void RiP_SBAwayController_frontLocked_animate_automatically(id obj, SEL sel, BOOL frontLocked, BOOL animate, BOOL automatically)
{
	if (frontLocked and sRipHood)
	{
		[sRipHood dismissController:nil animated:NO];
	}
	
	gSBAwayController_frontLocked_animate_automatically(obj, sel, frontLocked, animate, automatically);
}

#pragma mark -

static void RiP_CreateHoodController()
{
	if (sRipHood)
		return;
		
	NSBundle* menBundle = [NSBundle bundleForClass:[RipHoodController class]];
	
	sRipHood = [[RipHoodController alloc] initWithNibName:@"RipHood" bundle:menBundle];
}

static void RiP_InvokeRipHood()
{
	if (!sRipHood)
		RiP_CreateHoodController();
		
	if (sRipHood.view.superview != nil)
		return;
		
	CGRect r = sRipHood.view.frame;
	
	//BOOL isLandscape = ([[UIApplication sharedApplication] UIOrientation] != 0);
	BOOL isLandscape = NO;
	
	if (isLandscape)
	{
		r.origin.x = -r.size.width;
		r.origin.y = 0;
	}
	else
	{
		r.origin.y = -r.size.height;
		r.origin.x = 0;
	}

	//NSLog(@"Start frame = %@ (orientation = %d)", NSStringFromCGRect(r), [UIDevice currentDevice].orientation);
		
	sRipHood.view.frame = r;
	
	UIWindow* parentView = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	parentView.windowLevel = UIWindowLevelStatusBar;
	
	//UIView* parentView = [UIApplication sharedApplication].keyWindow;
	
	[sRipHood.view removeFromSuperview];
	[parentView addSubview:sRipHood.view];
	[parentView bringSubviewToFront:sRipHood.view];
	
	[sRipHood.overlayView removeFromSuperview];
	sRipHood.overlayView.alpha = .0;
	[parentView insertSubview:sRipHood.overlayView belowSubview:sRipHood.view];
	
	[parentView makeKeyAndVisible];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:.3];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	
	if (isLandscape)
	{
		r.origin.x = [UIApplication sharedApplication].statusBarFrame.size.height;
	}
	else
	{
		r.origin.y = [UIApplication sharedApplication].statusBarFrame.size.height;
	}
	
	//NSLog(@"End frame = %@", NSStringFromCGRect(r));
	
	sRipHood.view.frame = r;
	sRipHood.overlayView.alpha = .6;
	
	[UIView commitAnimations];
}

