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
    NSString* version = [info objectForKey:(id)kCFBundleVersionKey];
    NSString *message = [NSString stringWithFormat:@"You are using %@ v%@", appName,version];
    [[[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
}

- (IBAction)signOut:(id)sender {
    [UIAlertView showWithTitle:@"Sign Out" message:@"Are you sure you want to sign out?" action:@"YES" cancel:@"NO" completion:^{
        [WLSession clear];
        [[UIStoryboard storyboardNamed:WLSignUpStoryboard] present:YES];
    }];
}

@end
