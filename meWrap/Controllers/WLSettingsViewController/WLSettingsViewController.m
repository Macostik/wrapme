//
//  WLSettingsViewController.m
//  meWrap
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
#import "WLAPIRequest.h"
#import "PubNub+SharedInstance.h"
#import "WLAlertView.h"
#import "WLNotificationSubscription.h"

@interface WLSettingsViewController ()

@property (weak, nonatomic) IBOutlet UIButton *signOutButton;

@end

@implementation WLSettingsViewController

- (IBAction)about:(id)sender {
    NSString* appName = [NSBundle mainBundle].displayName;
    NSString* version = [NSBundle mainBundle].buildVersion;
    NSString* build = [NSBundle mainBundle].buildNumber;
    NSString *message = [NSString stringWithFormat:WLLS(@"formatted_about_message"), appName, version, build];
    [UIAlertController showWithMessage:message];
}

- (IBAction)signOut:(id)sender {
    [UIAlertController showWithTitle:WLLS(@"sign_out") message:WLLS(@"sign_out_confirmation") cancel:WLLS(@"cancel") action:WLLS(@"sign_out") completion:^{
        [[WLOperationQueue queueNamed:WLOperationFetchingDataQueue] cancelAllOperations];
        [[WLAPIManager manager].operationQueue cancelAllOperations];
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
    [[WLOperationQueue queueNamed:WLOperationFetchingDataQueue] cancelAllOperations];
    [[WLAPIManager manager].operationQueue cancelAllOperations];
    __weak WLUser *currentUser = [WLUser currentUser];
    __weak WLEntryManager *manager = [WLEntryManager manager];
    [[WLWrap entries] all:^(WLEntry *entry) {
        [manager uncacheEntry:entry];
        [manager.context deleteObject:entry];
    }];
    [[WLUser entries] all:^(WLEntry *entry) {
        if (entry != currentUser) {
            [manager uncacheEntry:entry];
            [manager.context deleteObject:entry];
        }
    }];
    [manager.context save:NULL];
    currentUser.wraps = [NSSet set];
    [[WLImageCache cache] clear];
    [[WLImageCache uploadingCache] clear];
    [[WLSystemImageCache instance] removeAllObjects];
    [[UIStoryboard storyboardNamed:WLMainStoryboard] present:YES];
}

- (void)addDemoImageWithCount:(NSUInteger)count {
    if (count == 0) return;
    
    NSString* stringUrl = count % 2 == 0 ? @"https://placeimg.com/640/1136/any" : @"https://placeimg.com/1136/640/any";
    __weak __typeof(self)weakSelf = self;
    [PHPhotoLibrary addImageAtFileUrl:[stringUrl URL] collectionTitle:WLAlbumName success:^{
        [weakSelf addDemoImageWithCount:count - 1];
    } failure:^(NSError *error) {
        
    }];
    
}

- (IBAction)showGroupChannels:(id)sender {
    [[PubNub sharedInstance] channelsForGroup:[WLNotificationCenter defaultCenter].userSubscription.name withCompletion:^(PNChannelGroupChannelsResult *result, PNErrorStatus *status) {
        NSMutableString *message = [NSMutableString string];
        NSMutableArray *channels = [result.data.channels mutableCopy];
        for (WLWrap *wrap in [WLUser currentUser].wraps) {
            if ([channels containsObject:wrap.identifier]) {
                [message appendFormat:@"subscribed %@ : %@\n", wrap.name, wrap.identifier];
                [channels removeObject:wrap.identifier];
            } else {
                [message appendFormat:@"not subscribed %@ : %@\n", wrap.name, wrap.identifier];
            }
        }
        [message appendFormat:@"\nother channels %@", channels];
        
        [[UIPasteboard generalPasteboard] setValue:message forPasteboardType:(id)kUTTypeText];
        
        [UIAlertController showWithTitle:[WLNotificationCenter defaultCenter].pushToken.description message:message buttons:@[@"OK"] completion:nil];
    }];
}

- (IBAction)showAPNSChannels:(id)sender {
    [[PubNub sharedInstance] pushNotificationEnabledChannelsForDeviceWithPushToken:[WLNotificationCenter defaultCenter].pushToken andCompletion:^(PNAPNSEnabledChannelsResult *result, PNErrorStatus *status) {
        NSMutableString *message = [NSMutableString string];
        NSMutableArray *channels = [result.data.channels mutableCopy];
        for (WLWrap *wrap in [WLUser currentUser].wraps) {
            if ([channels containsObject:wrap.identifier]) {
                [message appendFormat:@"enabled %@ : %@\n", wrap.name, wrap.identifier];
                [channels removeObject:wrap.identifier];
            } else {
                [message appendFormat:@"disabled %@ : %@\n", wrap.name, wrap.identifier];
            }
        }
        [message appendFormat:@"\nother channels %@", channels];
        
        [[UIPasteboard generalPasteboard] setValue:message forPasteboardType:(id)kUTTypeText];
        
        [UIAlertController showWithTitle:[WLNotificationCenter defaultCenter].pushToken.description message:message buttons:@[@"OK"] completion:nil];
    }];
}

@end