//
//  WLSettingsViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11/21/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLSettingsViewController.h"

@interface WLSettingsViewController ()

@end

@implementation WLSettingsViewController

- (IBAction)about:(id)sender {
    NSDictionary* info = [[NSBundle mainBundle] infoDictionary];
    NSString* appName = [info objectForKey:@"CFBundleDisplayName"]?:@"wrapLive";
    NSString* version = [info objectForKey:(id)kCFBundleVersionKey];
    NSString *message = [NSString stringWithFormat:@"You are using %@ v%@", appName,version];
    [[[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
}

@end
