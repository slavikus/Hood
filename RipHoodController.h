//
//  RipHoodController.h
//  HoodApp
//
//  Created by Slava Karpenko on 11/23/08.
//  Copyright 2008 Ripdev. All rights reserved.
//

#include <mach/mach.h>
#import <UIKit/UIKit.h>
#import "RipPieChartView.h"

@class RipHoodProcessListController;

@interface RipHoodController : UIViewController {
	IBOutlet UIControl*		overlayView;
	IBOutlet RipPieChartView* pieChart;
	
	IBOutlet UILabel*		freeLabel;
	IBOutlet UILabel*		activeLabel;
	IBOutlet UILabel*		inactiveLabel;
	IBOutlet UILabel*		wiredLabel;
	IBOutlet UILabel*		usedLabel;
	
	IBOutlet UIButton*		button1;
	IBOutlet UIButton*		button2;
	IBOutlet UIButton*		button3;
	IBOutlet UIButton*		button4;
	
	IBOutlet UIView*		pieView;
	IBOutlet UIView*		prView;
	IBOutlet RipHoodProcessListController* prController;
	
	@private
		mach_port_t				mHost;
		vm_size_t				mPageSize;
		vm_statistics_data_t	mVMStat;
		vm_size_t				mTotalPages;
		
		CGPoint					mPRViewOrigin;
		
		NSMutableArray*			mAirportButtons;
		NSMutableArray*			mBluetoothButtons;
		NSMutableArray*			mEDGEButtons;
		NSMutableArray*			mQuitButtons; 
		
		NSDictionary*			mButtonsIndex;
	
		void*					mWiFiManagerClient;
}

@property (nonatomic, readonly) UIControl* overlayView;
@property (readonly) BOOL airportEnabled;
@property (assign) BOOL edgeEnabled;

- (IBAction)dismissController:(id)sender;
- (void)dismissController:(id)sender animated:(BOOL)animated;

- (IBAction)doRespring:(UIButton*)sender;
- (IBAction)doAirport:(UIButton*)sender;
- (IBAction)doBluetooth:(UIButton*)sender;
- (IBAction)doEDGE:(UIButton*)sender;
- (IBAction)doNothing:(UIButton*)sender;

- (IBAction)doSwitchToProcessList:(id)sender;

- (void)_updateMemoryPieChart;
- (void)_fetchVMStatistics;

- (void)updateLabel:(UILabel*)label withPages:(natural_t)pages name:(NSString*)name;
- (NSString *)byteSizeDescription:(double)dBytes;

- (void)_setupFromPrefs;
- (void)_setupButton:(UIButton*)button withID:(CFStringRef)ID;
- (void)_updateButtonStates;
@end
