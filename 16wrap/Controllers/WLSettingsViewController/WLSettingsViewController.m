//
//  WLSettingsViewController.m
//  moji
//
//  Created by Ravenpod on 11/21/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLSettingsViewController.h"
#import "WLNavigationHelper.h"
#import "WLToast.h"
#import "WLButton.h"
#import "WLAlertView.h"
#import "WLNotificationCenter.h"
#import "PHPhotoLibrary+Helper.h"

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
    [self addDemoImageWithCount:5];
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

- (void)addDemoImageWithCount:(NSUInteger)count {
    if (count == 0) return;
    
    NSString* stringUrl = count % 2 == 0 ? @"https://placeimg.com/640/1136/any" : @"https://placeimg.com/1136/640/any";
    __weak __typeof(self)weakSelf = self;
    NSString *titleAlbum = @"test album";
    NSURL *url = [NSURL URLWithString:stringUrl];
    [PHPhotoLibrary addNewAssetWithImageAtFileUrl:url
                       toAssetCollectionWithTitle:titleAlbum
                                completionHandler:^(BOOL success, NSError *error) {
                                    if  (success) [weakSelf addDemoImageWithCount:count - 1];
                                }];
}


@end