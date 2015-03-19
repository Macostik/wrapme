//
//  WLSettingsViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11/21/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLSettingsViewController.h"
#import "WLAPIManager.h"
#import "WLSession.h"
#import "WLNavigation.h"
#import "UIAlertView+Blocks.h"
#import "NSDate+Formatting.h"

@interface WLSettingsViewController ()

@property (weak, nonatomic) IBOutlet UIButton *signOutButton;

@end

@implementation WLSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.signOutButton.hidden = [WLAPIManager instance].environment.isProduction;
}

- (IBAction)about:(id)sender {
    NSDictionary* info = [[NSBundle mainBundle] infoDictionary];
    NSString* appName = [info objectForKey:@"CFBundleDisplayName"]?:@"wrapLive";
    NSString* version = [info objectForKey:@"CFBundleShortVersionString"];
    NSString* build = [info objectForKey:(id)kCFBundleVersionKey];
    NSString *message = [NSString stringWithFormat:WLLS(@"You are using %@\nv%@\nBuild %@"), appName, version, build];
    [UIAlertView showWithMessage:message];
}

- (IBAction)signOut:(id)sender {
    [UIAlertView showWithTitle:WLLS(@"Sign Out") message:WLLS(@"Are you sure you want to sign out?") action:WLLS(@"YES") cancel:WLLS(@"NO") completion:^{
        [WLSession clear];
        [[UIStoryboard storyboardNamed:WLSignUpStoryboard] present:YES];
    }];
}

@end
