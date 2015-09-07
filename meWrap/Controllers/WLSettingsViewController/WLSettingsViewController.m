//
//  WLSettingsViewController.m
//  meWrap
//
//  Created by Ravenpod on 11/21/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLSettingsViewController.h"
#import "WLNavigationHelper.h"
#import "ALAssetsLibrary+Additions.h"
#import "WLToast.h"
#import "WLButton.h"
#import "WLAlertView.h"
#import "WLNotificationCenter.h"

@interface WLSettingsViewController ()

@property (weak, nonatomic) IBOutlet UIButton *signOutButton;

@end

@implementation WLSettingsViewController

- (IBAction)about:(id)sender {
    NSString* appName = NSMainBundle.displayName;
    NSString* version = NSMainBundle.buildVersion;
    NSString* build = NSMainBundle.buildNumber;
    NSString *message = [NSString stringWithFormat:WLLS(@"formatted_about_message"), appName, version, build];
    [WLAlertView showWithMessage:message];
}

- (IBAction)signOut:(id)sender {
    [WLAlertView showWithTitle:WLLS(@"sign_out") message:WLLS(@"sign_out_confirmation") cancel:WLLS(@"cancel") action:WLLS(@"sign_out") completion:^{
        [[WLNotificationCenter defaultCenter] clear];
        [WLSession clear];
        [[UIStoryboard storyboardNamed:WLSignUpStoryboard] present:YES];
    }];
}

- (IBAction)addDemoImages:(id)sender {
    [ALAssetsLibrary addDemoImages:5];
    [WLToast showWithMessage:@"5 demo images will be added to Photos"];
}

- (IBAction)cleanCache:(WLButton*)sender {
    WLUser *currentUser = [WLUser currentUser];
    [[WLEntry entries] all:^(WLEntry *entry) {
        if (entry != currentUser) {
            [[WLEntryManager manager] uncacheEntry:entry];
            [[WLEntryManager manager].context deleteObject:entry];
        }
    }];
    [[WLEntryManager manager].context save:NULL];
    currentUser.wraps = [NSSet set];
    [[WLImageCache cache] clear];
    [[WLImageCache uploadingCache] clear];
    [[UIStoryboard storyboardNamed:WLMainStoryboard] present:YES];
}

@end
