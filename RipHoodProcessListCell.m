//
//  RipHoodProcessListCell.m
//  Hood
//
//  Created by Slava Karpenko on 11/27/08.
//  Copyright 2008 Ripdev. All rights reserved.
//

#import "RipHoodProcessListCell.h"


@implementation RipHoodProcessListCell

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) {
        self.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
		self.textColor = [UIColor whiteColor];
		self.selectedTextColor = [UIColor blackColor];
		self.selectionStyle = UITableViewCellSelectionStyleGray;
		
		// Add fields
		UILabel* label = nil;
		
		// pid
		label = [[UILabel alloc] initWithFrame:CGRectMake(30, 0, 40, 20)];
		label.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
		label.textColor = [UIColor lightGrayColor];
		label.shadowColor = [UIColor blackColor];
		label.shadowOffset = CGSizeMake(1,1);
		label.textAlignment = UITextAlignmentCenter;
		label.backgroundColor = [UIColor clearColor];
		[self.contentView addSubview:label];
		pidLabel = label;
		[label release];	// this may sound odd, but we dont care about retaining label here, as it's inserted in our contentView anyway, and if it destructs, we will die too.
		
		// name
		label = [[UILabel alloc] initWithFrame:CGRectMake(30+40+5, 0, 140, 20)];
		label.font = [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize]];
		label.textColor = [UIColor whiteColor];
		label.shadowColor = [UIColor blackColor];
		label.shadowOffset = CGSizeMake(1,1);
		label.backgroundColor = [UIColor clearColor];
		label.textAlignment = UITextAlignmentLeft;
		[self.contentView addSubview:label];
		nameLabel = label;
		[label release];	// this may sound odd, but we dont care about retaining label here, as it's inserted in our contentView anyway, and if it destructs, we will die too.
		
		// misc
		label = [[UILabel alloc] initWithFrame:CGRectMake(30+40+5+140, 0, 100, 20)];
		label.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
		label.textColor = [UIColor lightGrayColor];
		label.shadowColor = [UIColor blackColor];
		label.shadowOffset = CGSizeMake(1,1);
		label.textAlignment = UITextAlignmentRight;
		label.backgroundColor = [UIColor clearColor];
		[self.contentView addSubview:label];
		miscLabel = label;
		[label release];	// this may sound odd, but we dont care about retaining label here, as it's inserted in our contentView anyway, and if it destructs, we will die too.

		iconView = [[UIImageView alloc] initWithFrame:CGRectMake(4,0, 24, 24)];
		iconView.contentMode = UIViewContentModeScaleAspectFill;
		iconView.clipsToBounds = YES;
		[self.contentView addSubview:iconView];
		[iconView release];
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)dealloc {
	self.processInfo = nil;
	
    [super dealloc];
}

- (void)setProcessInfo:(NSMutableDictionary*)pinfo
{
	[processInfo release];
	
	processInfo = [pinfo retain];
	
	
	/*
					[pinfo setObject:[NSNumber numberWithUnsignedInt:pc[i].kp_proc.p_swtime] forKey:@"swtime"];
					[pinfo setObject:[NSNumber numberWithUnsignedInt:pc[i].kp_proc.p_slptime] forKey:@"slptime"];
					[pinfo setObject:[NSNumber numberWithUnsignedInt:pc[i].kp_proc.p_estcpu] forKey:@"estcpu"];
					[pinfo setObject:[NSNumber numberWithUnsignedInt:pc[i].kp_proc.p_cpticks] forKey:@"cpticks"];
					[pinfo setObject:[NSNumber numberWithUnsignedInt:pc[i].kp_proc.p_pctcpu] forKey:@"pctcpu"];
	*/
		
	pidLabel.text = [NSString stringWithFormat:@"%u", [[processInfo objectForKey:@"pid"] unsignedIntValue]];
	nameLabel.text = [processInfo objectForKey:@"name"];
	
	gid_t group = [[processInfo objectForKey:@"gid"] intValue];
	if (501 != group)
	{
		miscLabel.text = @"root";
		miscLabel.textColor = [UIColor colorWithRed:1. green:.3 blue:.3 alpha:1.];
	}
	else
	{
		miscLabel.text = @"user";
		miscLabel.textColor = [UIColor colorWithRed:.3 green:1. blue:.3 alpha:1.];	
	}
	
	iconView.image = nil;
	
	UIImage* icon = nil;
	//NSBundle* bundle;
	
	
	if ((icon = [processInfo objectForKey:@"icon"]) != nil)
	{
		if (![icon isKindOfClass:[NSNull class]])
			iconView.image = icon;
	}
/*	else if ((bundle = [processInfo objectForKey:@"bundle"]) != nil)
	{
		[processInfo setObject:[NSNull null] forKey:@"icon"];
		NSString* iconName = [[bundle infoDictionary] objectForKey:@"CFBundleIconFile"];
		NSString* path = nil;

		if (iconName && [iconName length])
			path = [bundle pathForResource:[iconName stringByDeletingPathExtension] ofType:[iconName pathExtension]];
		else
			path = [bundle pathForResource:@"icon" ofType:@"png"];
		
		if (path)
		{
			icon = [[UIImage alloc] initWithContentsOfFile:path];
			if (icon)
			{
				iconView.image = icon;
				[processInfo setObject:icon forKey:@"icon"];
				[icon release];
				icon = nil;
			}
		}
	} */
	
	if (!iconView.image)
	{
		// set default
		icon = [UIImage imageWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"RipHoodDefaultAppIcon" ofType:@"png"]];
		
		[processInfo setObject:icon?(id)icon:(id)[NSNull null] forKey:@"icon"];
		iconView.image = icon;
	}
}

- (NSMutableDictionary*)processInfo
{
	return processInfo;
}


@end
