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
    NSString* version = [info objectForKey:(id)kCFBundleVersionKey];
    NSString *message;
    if ([WLAPIManager instance].environment.isProduction) {
        message = [NSString stringWithFormat:@"You are using %@ v%@", appName,version];
    } else {
        NSMutableString *_message = [NSMutableString stringWithFormat:@"You are using %@ v%@", appName,version];
        NSString *sourceFile = [[NSBundle mainBundle] pathForResource:@"WLAPIEnvironmentProduction" ofType:@"plist"];
        NSDate *lastModif = [[[NSFileManager defaultManager] attributesOfItemAtPath:sourceFile error:NULL] objectForKey:NSFileModificationDate];
        if (lastModif) {
            [_message appendFormat:@"\nInstalled %@", [lastModif stringWithFormat:@"MMM d, yyyy hh:mm:ss"]];
        }

#if CI_BUILD_NUMBER > 0
        [_message appendFormat:@"\nJenkins build number %d", CI_BUILD_NUMBER];
#endif
        message = _message;
    }
    [UIAlertView showWithMessage:message];
}

- (IBAction)signOut:(id)sender {
    [UIAlertView showWithTitle:@"Sign Out" message:@"Are you sure you want to sign out?" action:@"YES" cancel:@"NO" completion:^{
        [WLSession clear];
        [[UIStoryboard storyboardNamed:WLSignUpStoryboard] present:YES];
    }];
}

@end
