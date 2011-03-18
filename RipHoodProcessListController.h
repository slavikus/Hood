//
//  RipHoodProcessListController.h
//  Hood
//
//  Created by Slava Karpenko on 11/26/08.
//  Copyright 2008 Ripdev. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RipHoodController;

@interface RipHoodProcessListController : UITableViewController {
	IBOutlet UITableView*	prTable;
	IBOutlet RipHoodController* hController;
	BOOL	shouldTrack;
	
	@private
		NSMutableArray*			processes;
		NSMutableDictionary*	pidInfo;

		BOOL hasNoRootPermissions;
		BOOL hasNoRootPermissionsInitialized;
}

@property (nonatomic, assign) BOOL shouldTrack;

- (void)beginTracking;
- (NSString*)nameForProcessWithPID:(pid_t)pidNum;

- (void)_initializeHasRootPermissions;
- (void)killPID:(pid_t)pid;

@end
