//
//  HoodPrefsController.h
//  Hood
//
//  Created by Slava Karpenko on 12/4/08.
//  Copyright 2008 Ripdev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Preferences/Preferences.h>

@interface HoodPrefsController : PSListController
{
}

- (id)specifiers;
- (void)set:(id)val specifier:(PSSpecifier *)spec;
- (id)get:(PSSpecifier *)spec;
@end