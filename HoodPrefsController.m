//
//  HoodPrefsController.m
//  Hood
//
//  Created by Slava Karpenko on 12/4/08.
//  Copyright 2008 Ripdev. All rights reserved.
//

#import "HoodPrefsController.h"


@implementation HoodPrefsController

- (id)specifiers
{
	NSMutableArray * specs = [[self loadSpecifiersFromPlistName:@"HoodPrefs" target:self] retain];
	
	return specs;
}

-(void)set:(id)val specifier:(PSSpecifier *)spec
{
	CFStringRef key = (CFStringRef)[spec propertyForKey:PSKeyNameKey];
	CFStringRef def = (CFStringRef)[spec propertyForKey:PSDefaultsKey];

	CFPreferencesSetAppValue(key, val, def);
	CFPreferencesAppSynchronize(def);
	
	// broadcast changes
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.ripdev.hood.pepyaka"), NULL, NULL, false);
}

-(id)get:(PSSpecifier *)spec
{
	CFStringRef key = (CFStringRef)[spec propertyForKey:PSKeyNameKey];
	CFStringRef def = (CFStringRef)[spec propertyForKey:PSDefaultsKey];
	
	CFPreferencesAppSynchronize(def);

	id val = (id)CFPreferencesCopyAppValue(key, def);
	if (val == nil)
		val = [spec propertyForKey:PSDefaultValueKey];
	
	return val;
}
@end
