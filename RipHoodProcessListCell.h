//
//  RipHoodProcessListCell.h
//  Hood
//
//  Created by Slava Karpenko on 11/27/08.
//  Copyright 2008 Ripdev. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RipHoodProcessListCell : UITableViewCell {
	NSMutableDictionary* processInfo;
	
	@private
		UILabel*		pidLabel;
		UILabel*		nameLabel;
		UILabel*		miscLabel;
		UIImageView*	iconView;
		
}

@property (nonatomic, retain) NSMutableDictionary* processInfo;

@end
