//
//  RipHoodController.m
//  Hood
//
//  Created by Slava Karpenko on 11/23/08.
//  Copyright 2008 Ripdev. All rights reserved.
//

#include <mach/mach.h>
#include <sys/types.h>
#include <sys/sysctl.h>

#import "BluetoothManager.h"
#import "RipHoodController.h"
#import "PSSystemConfiguration.h"
#import "RipHoodProcessListController.h"

extern NSString* SBSCopyFrontmostApplicationDisplayIdentifier();
extern pid_t SBGetPIDForBundleIdentifier(const char* bundleIdentifier, pid_t* outPid);
extern int SBSProcessIDForDisplayIdentifier(NSString* bundleIdentifier, pid_t* outPid);
extern void CTRegistrationSetDataContextActive(int inContext, int inActive);

extern void WiFiDeviceClientSetPower(void* device, int powerState);
extern int WiFiDeviceClientGetPower(void* device);

extern void* WiFiManagerClientCreate(CFAllocatorRef allocator, void* null);
extern CFArrayRef WiFiManagerClientCopyDevices(void* manager);


#define kHoodAppID					CFSTR("com.ripdev.hood")
#define kHoodEnableProcessList		CFSTR("EnableProcessList")
#define kHoodButton1				CFSTR("Button1")
#define kHoodButton2				CFSTR("Button2")
#define kHoodButton3				CFSTR("Button3")
#define kHoodButton4				CFSTR("Button4")

struct RipHoodButtonActions {
	CFStringRef			actionTag;
	NSString*			sel;
	NSString*			selectedImageName;
	NSString*			imageName;
} gRipHoodButtonActions[] = {
	{
		CFSTR(""),
		@"doNothing:",
		nil,
		nil
	},
	{
		CFSTR("quit"),
		@"doRespring:",
		@"RipHoodRespringIcon.png",
		@"RipHoodRespringIconOff.png",
	},
	{
		CFSTR("wifi"),
		@"doAirport:",
		@"RipHoodAirportIcon.png",
		@"RipHoodAirportIconOff.png",
	},
	{
		CFSTR("bluetooth"),
		@"doBluetooth:",
		@"RipHoodBluetoothIcon.png",
		@"RipHoodBluetoothIconOff.png",
	},
	{
		CFSTR("edge"),
		@"doEDGE:",
		@"RipHoodEDGEIcon.png",
		@"RipHoodEDGEIconOff.png",
	},
	{
		NULL,
		nil,
		nil,
		nil
	}
};

static CFStringRef gRipHoodButtonDefaults[4] = {
	CFSTR("wifi"),
	CFSTR("bluetooth"),
	CFSTR("edge"),
	CFSTR("quit")
};

@implementation RipHoodController
@synthesize overlayView;

// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad {
	mHost = mach_host_self();

	if (host_page_size(mHost, &mPageSize) != KERN_SUCCESS)
		mPageSize = 4096;
		
	mTotalPages = 0;
	
	size_t bufSize = sizeof(mTotalPages);
	if (sysctlbyname("hw.physmem", &mTotalPages, &bufSize, NULL, 0) == 0)
	{
		mTotalPages /= mPageSize;
	}
	
	[BluetoothManager initialize];
	
	mWiFiManagerClient = WiFiManagerClientCreate(kCFAllocatorDefault, NULL);
	
	mPRViewOrigin = prView.frame.origin;
	
	mAirportButtons = [[NSMutableArray arrayWithCapacity:0] retain];
	mEDGEButtons = [[NSMutableArray arrayWithCapacity:0] retain];
	mBluetoothButtons = [[NSMutableArray arrayWithCapacity:0] retain];
	mQuitButtons = [[NSMutableArray arrayWithCapacity:0] retain];
	
	mButtonsIndex = [[NSDictionary dictionaryWithObjectsAndKeys:	mAirportButtons,		@"wifi",
																	mEDGEButtons,			@"edge",
																	mBluetoothButtons,		@"bluetooth",
																	mQuitButtons,			@"quit",
																	nil] retain];
	
	// read in prefs and set up buttons
	[self _setupFromPrefs];
	
    [super viewDidLoad];
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	return YES;
//	NSLog(@"shouldAutorotateToInterfaceOrientation: %d", interfaceOrientation);
 //   return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
	[(id)mWiFiManagerClient release];
	
    [super dealloc];
}

- (IBAction)dismissController:(id)sender
{
	[self dismissController:sender animated:YES];
}

- (void)dismissController:(id)sender animated:(BOOL)animated
{
	if (animated)
	{
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:.3];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
		
		CGRect r = self.view.frame;
		
		r.origin.y = -r.size.height;
		self.view.frame = r;

		self.overlayView.alpha = .0;
		
		[UIView commitAnimations];
	}
	else
	{
		CGRect r = self.view.frame;
		
		r.origin.y = -r.size.height;
		self.view.frame = r;

		self.overlayView.alpha = .0;	

		UIWindow* windowToDispose = self.view.window;
		
		[self.view removeFromSuperview];
		[self.overlayView removeFromSuperview];
		
		windowToDispose.hidden = YES;
		[windowToDispose release];
	}
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
	UIWindow* windowToDispose = self.view.window;
	
	[self.view removeFromSuperview];
	[self.overlayView removeFromSuperview];
	
	windowToDispose.hidden = YES;
	[windowToDispose release];
}

- (void)viewDidAppear:(BOOL)animated    // Called when the view is about to made visible. Default does nothing
{
	[self _updateMemoryPieChart];
	[self _updateButtonStates];
}

#pragma mark -

- (void)killApplication
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSString* frontmostAppIdentifier = SBSCopyFrontmostApplicationDisplayIdentifier();
	
	if (frontmostAppIdentifier != nil)
	{
		pid_t pid = 0;
		if (SBSProcessIDForDisplayIdentifier(frontmostAppIdentifier, &pid))
		{
			NSLog(@"kill %d", pid);
			kill(pid, SIGTERM);
		}
		else
		{
			Class SBUIControllerClass = NSClassFromString(@"SBUIController");
			
			if (SBUIControllerClass)
			{
				id sharedController = objc_msgSend(SBUIControllerClass, NSSelectorFromString(@"sharedInstance"));
				
				if ([sharedController respondsToSelector:NSSelectorFromString(@"quitTopApplication")])
				{
					objc_msgSend(sharedController, NSSelectorFromString(@"quitTopApplication"));
				}
			}
		}

		[frontmostAppIdentifier release];
	}
	else
	{
		[[UIApplication sharedApplication] performSelectorOnMainThread:@selector(relaunchSpringBoard) withObject:nil waitUntilDone:NO];
		//objc_msgSend([UIApplication sharedApplication], @selector(relaunchSpringBoard));
	}
	
	[pool release];
}

- (IBAction)doRespring:(UIButton*)sender
{
	[self performSelectorInBackground:@selector(killApplication) withObject:nil];
}

- (IBAction)doNothing:(UIButton*)sender
{
}

- (IBAction)doAirport:(UIButton*)sender
{
	char newPower = !self.airportEnabled;
	
	if (!mWiFiManagerClient)
		return;
	
	NSArray* devices = (NSArray*)WiFiManagerClientCopyDevices(mWiFiManagerClient);
	if (devices && [devices count])
	{
		void* device = [devices objectAtIndex:0];
		
		WiFiDeviceClientSetPower(device, (int)newPower);
	}
	
	[devices release];
	
	for (UIButton* button in mAirportButtons)
		button.selected = newPower;
}

- (IBAction)doBluetooth:(UIButton*)sender
{
	BOOL enabled = !sender.selected;
	
	[[BluetoothManager sharedInstance] setEnabled:enabled];
	
	for (UIButton* button in mBluetoothButtons)
		button.selected = enabled;
}

- (IBAction)doEDGE:(UIButton*)sender
{
	BOOL enabled = !sender.selected;
	
	self.edgeEnabled = enabled;
	
	for (UIButton* button in mEDGEButtons)
		button.selected = enabled;
}


#pragma mark -

- (void)updateLabel:(UILabel*)label withPages:(natural_t)pages name:(NSString*)name
{
	label.text = [NSString stringWithFormat:@"%@: %@", name, [self byteSizeDescription:pages*mPageSize]];
}

- (NSString *)byteSizeDescription:(double)dBytes {

	if(dBytes == 0) {
		return @"0 bytes";
	} else if(dBytes <= pow(2, 10)) {
		return [NSString stringWithFormat:@"%0.0f bytes", dBytes];
	} else if(dBytes <= pow(2, 20)) {
		return [NSString stringWithFormat:@"%0.1f KB", dBytes / pow(1024, 1)];
	} else if(dBytes <= pow(2, 30)) {
		return [NSString stringWithFormat:@"%0.1f MB", dBytes / pow(1024, 2)];
	} else if(dBytes <= pow(2, 40)) {
		return [NSString stringWithFormat:@"%0.1f GB", dBytes / pow(1024, 3)];
	} else {
		return [NSString stringWithFormat:@"%0.1f TB", dBytes / pow(1024, 4)];
	}
}

- (void)_updateMemoryPieChart
{
	if (!self.view.superview || !pieView.alpha)
		return;
		
	[self _fetchVMStatistics];
	
	[pieChart.slices removeAllObjects];
	
	double total_pages = mVMStat.free_count + mVMStat.active_count + mVMStat.inactive_count + mVMStat.wire_count;
	
	double free = (double)mVMStat.free_count / (double)total_pages;
	double active = (double)mVMStat.active_count / (double)total_pages;
	double inactive = (double)mVMStat.inactive_count / (double)total_pages;
	double wired = (double)mVMStat.wire_count / (double)total_pages;
	
	[pieChart.slices addObject:[RipPieChartSlice sliceWithPercent:free color:[UIColor greenColor]]];
	[pieChart.slices addObject:[RipPieChartSlice sliceWithPercent:active color:[UIColor redColor]]];
	[pieChart.slices addObject:[RipPieChartSlice sliceWithPercent:inactive color:[UIColor orangeColor]]];
	[pieChart.slices addObject:[RipPieChartSlice sliceWithPercent:wired color:[UIColor blueColor]]];
	
	[pieChart setNeedsDisplay];
	
	[self updateLabel:freeLabel withPages:mVMStat.free_count name:@"Free"];
	[self updateLabel:activeLabel withPages:mVMStat.active_count name:@"Active"];
	[self updateLabel:inactiveLabel withPages:mVMStat.inactive_count name:@"Inactive"];
	[self updateLabel:wiredLabel withPages:mVMStat.wire_count name:@"Wired"];
	[self updateLabel:usedLabel withPages:(mTotalPages - mVMStat.free_count) name:@"Used"];
	
	[self performSelector:@selector(_updateMemoryPieChart) withObject:nil afterDelay:0.5];
}

- (void)_fetchVMStatistics
{
	unsigned int count = HOST_VM_INFO_COUNT;
	if (host_statistics(mHost, HOST_VM_INFO, (host_info_t)&mVMStat, &count) != KERN_SUCCESS) {
		bzero(&mVMStat, sizeof(mVMStat));
	}
}

#pragma mark -

- (BOOL)airportEnabled
{
	char power = NO;
	
	if (!mWiFiManagerClient)
		return NO;
	
	NSArray* devices = (NSArray*)WiFiManagerClientCopyDevices(mWiFiManagerClient);
	if (devices && [devices count])
	{
		void* device = [devices objectAtIndex:0];
	
		power = WiFiDeviceClientGetPower(device);
	}
	
	[devices release];
	return power;
}

- (BOOL)edgeEnabled
{
	NSString* dataServiceID = [[PSSystemConfiguration sharedInstance] dataServiceID];
	
	if (dataServiceID)
	{
		id val = [[PSSystemConfiguration sharedInstance] interfaceConfigurationValueForKey:@"Available" serviceID:dataServiceID];
		
		return [val boolValue];
	}
	
	return NO;
}

- (void)setEdgeEnabled:(BOOL)e
{
	if (self.edgeEnabled == e)
		return;
		
	NSNumber* enabled = [NSNumber numberWithInt:e?1:0];
	
	[[PSSystemConfiguration sharedInstance] setInterfaceConfigurationValue:enabled forKey:@"Available" serviceID:[[PSSystemConfiguration sharedInstance] dataServiceID]];
	
	CTRegistrationSetDataContextActive(0, e ? 1 : 0);
	
	[self performSelector:@selector(_edgeEnabledChanged) withObject:nil afterDelay:.5];
}

- (void)_edgeEnabledChanged
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SBDataConnectionTypeChangedNotification" object:nil userInfo:nil];
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.apple.springboard.edgeEnabledChanged"), NULL, NULL, TRUE);
}

#pragma mark -

- (IBAction)doSwitchToProcessList:(id)sender
{
	BOOL prIsVisible = (prView.frame.origin.y != mPRViewOrigin.y);
	CGRect r = prView.frame;
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:.2];

	if (prIsVisible)
	{
		prController.shouldTrack = NO;
		r.origin.y = mPRViewOrigin.y;
		pieView.alpha = 1.;
		[self performSelector:@selector(_updateMemoryPieChart) withObject:nil afterDelay:0.5];
	}
	else
	{
		prController.shouldTrack = YES;
		r.origin.y = pieView.frame.origin.y;
		pieView.alpha = .0;
	}
	
	[prController beginTracking];
	
	prView.frame = r;
	
	[UIView commitAnimations];
}

#pragma mark -

- (void)_setupFromPrefs
{
	CFPreferencesAppSynchronize(kHoodAppID);
	int i;
	
	[mBluetoothButtons removeAllObjects];
	[mAirportButtons removeAllObjects];
	[mEDGEButtons removeAllObjects];
	[mQuitButtons removeAllObjects];
	
	for (i=1;i<=4;i++)
	{
		NSString* prefname = [NSString stringWithFormat:@"Button%d", i];
		UIButton* button = nil;
		
		if (1 == i)
			button = button1;
		else if (2 == i)
			button = button2;
		else if (3 == i)
			button = button3;
		else
			button = button4;
		
		CFStringRef value = (CFStringRef)CFPreferencesCopyAppValue((CFStringRef)prefname, kHoodAppID);
		if (value)
		{
			[self _setupButton:button withID:value];
			CFRelease(value);
		}
		else
			[self _setupButton:button withID:gRipHoodButtonDefaults[i-1]];
	}
	
	Boolean keyExists = FALSE;
	if (CFPreferencesGetAppBooleanValue(kHoodEnableProcessList, kHoodAppID, &keyExists) && keyExists)
	{
		prView.hidden = NO;
	}
	else
	{
		prView.hidden = YES;
		
		// check if it was visible before
		if ((prView.frame.origin.y != mPRViewOrigin.y))
		{
			[self doSwitchToProcessList:nil];
		}
	}
	
	[self _updateButtonStates];
}

- (void)_setupButton:(UIButton*)button withID:(CFStringRef)ID
{
	// find an appropriate match
	struct RipHoodButtonActions* act = NULL;
	int i;
	
	for (i=0; gRipHoodButtonActions[i].actionTag; i++)
	{
		if ([(NSString*)gRipHoodButtonActions[i].actionTag isEqualToString:(NSString*)ID])
		{
			act = &gRipHoodButtonActions[i];
			break;
		}
	}
	
	// first, set up a dull button action
	NSArray* actions = [button actionsForTarget:self forControlEvent:UIControlEventTouchDown];
	for (NSString* sel in actions)
		[button removeTarget:self action:NSSelectorFromString(sel) forControlEvents:UIControlEventTouchDown];
	
	[button setImage:nil forState:UIControlStateNormal];
	[button setImage:nil forState:UIControlStateHighlighted];
	[button setImage:nil forState:UIControlStateSelected];
	
	// now set up the actions, if any
	if (act)
	{
		UIImage* normalImage = nil;
		UIImage* selectedImage = nil;
		
		if (act->imageName)
		{
			NSString* path = [[NSBundle bundleForClass:[self class]] pathForResource:[act->imageName stringByDeletingPathExtension] ofType:[act->imageName pathExtension]];
			if (path)
				normalImage = [UIImage imageWithContentsOfFile:path];
		}

		if (act->selectedImageName)
		{
			NSString* path = [[NSBundle bundleForClass:[self class]] pathForResource:[act->selectedImageName stringByDeletingPathExtension] ofType:[act->selectedImageName pathExtension]];
			if (path)
				selectedImage = [UIImage imageWithContentsOfFile:path];
		}
		
		[button setImage:normalImage forState:UIControlStateNormal];
		[button setImage:selectedImage forState:UIControlStateHighlighted];
		[button setImage:selectedImage forState:UIControlStateSelected];
	
		if (act->sel)
		{
			SEL sel = NSSelectorFromString(act->sel);
			
			if (sel)
			{
				[button addTarget:self action:sel forControlEvents:UIControlEventTouchDown];
			}
		}
		
		[[mButtonsIndex objectForKey:(NSString*)act->actionTag] addObject:button];
	}
}

- (void)_updateButtonStates
{
	BOOL enabled = [[BluetoothManager sharedInstance] enabled];
	for (UIButton* button in mBluetoothButtons)
		button.selected = enabled;

	enabled = self.airportEnabled;
	for (UIButton* button in mAirportButtons)
		button.selected = enabled;
	
	enabled = self.edgeEnabled;
	for (UIButton* button in mEDGEButtons)
		button.selected = enabled;
		
	for (UIButton* button in mQuitButtons)
		button.selected = NO;
}

@end
