//
//  WLSettingsViewController.m
//  meWrap
//
//  Created by Ravenpod on 11/21/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLSettingsViewController.h"
#import "WLToast.h"
#import "WLButton.h"
#import "WLNotificationCenter.h"
#import "WLAPIRequest.h"
#import "PubNub+SharedInstance.h"
#import "WLNotificationSubscription.h"

@interface WLSettingsViewController ()

@property (weak, nonatomic) IBOutlet UIButton *signOutButton;

@end

@implementation WLSettingsViewController

- (IBAction)about:(id)sender {
    NSString* appName = [NSBundle mainBundle].displayName;
    NSString* version = [NSBundle mainBundle].buildVersion;
    NSString* build = [NSBundle mainBundle].buildNumber;
    NSString *message = [NSString stringWithFormat:@"formatted_about_message".ls, appName, version, build];
    [[UIAlertController alert:message] show];
}

- (IBAction)signOut:(id)sender {
    [[[[UIAlertController alert:@"sign_out".ls message:@"sign_out_confirmation".ls] action:@"cancel".ls] action:@"sign_out".ls handler:^(UIAlertAction *action){
        [[WLOperationQueue queueNamed:WLOperationFetchingDataQueue] cancelAllOperations];
        [[WLAPIManager manager].operationQueue cancelAllOperations];
        [[WLNotificationCenter defaultCenter] clear];
        [[NSUserDefaults standardUserDefaults] clear];
        [[UIStoryboard signUp] present:YES];
        [[WLWhatsUpSet sharedSet] resetEntries:nil];
    }] show];
}

- (IBAction)addDemoImages:(id)sender {
    [self addDemoImageWithCount:5];
    [WLToast showWithMessage:@"5 demo images will be added to Photos"];
}

- (IBAction)cleanCache:(WLButton*)sender {
    [[WLOperationQueue queueNamed:WLOperationFetchingDataQueue] cancelAllOperations];
    [[WLAPIManager manager].operationQueue cancelAllOperations];
    __weak User *currentUser = [User currentUser];
    __weak EntryContext *context = EntryContext.sharedContext;
    [[Wrap entries] all:^(Entry *entry) {
        [context uncacheEntry:entry];
        [context deleteObject:entry];
    }];
    [[User entries] all:^(Entry *entry) {
        if (entry != currentUser) {
            [context uncacheEntry:entry];
            [context deleteObject:entry];
        }
    }];
    [context save:NULL];
    currentUser.wraps = [NSSet set];
    [[WLImageCache defaultCache] clear];
    [[WLImageCache uploadingCache] clear];
    [[SystemImageCache instance] removeAllObjects];
    [[UIStoryboard main] present:YES];
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
        for (Wrap *wrap in [User currentUser].wraps) {
            if ([channels containsObject:wrap.identifier]) {
                [message appendFormat:@"subscribed %@ : %@\n", wrap.name, wrap.identifier];
                [channels removeObject:wrap.identifier];
            } else {
                [message appendFormat:@"not subscribed %@ : %@\n", wrap.name, wrap.identifier];
            }
        }
        [message appendFormat:@"\nother channels %@", channels];
        
        [[UIPasteboard generalPasteboard] setValue:message forPasteboardType:(id)kUTTypeText];
        
        NSString *token = [WLNotificationCenter defaultCenter].pushToken.description;
        [[[UIAlertController alert:token message:message] action:@"ok".ls] show];
    }];
}

- (IBAction)showAPNSChannels:(id)sender {
    [[PubNub sharedInstance] pushNotificationEnabledChannelsForDeviceWithPushToken:[WLNotificationCenter defaultCenter].pushToken andCompletion:^(PNAPNSEnabledChannelsResult *result, PNErrorStatus *status) {
        NSMutableString *message = [NSMutableString string];
        NSMutableArray *channels = [result.data.channels mutableCopy];
        for (Wrap *wrap in [User currentUser].wraps) {
            if ([channels containsObject:wrap.identifier]) {
                [message appendFormat:@"enabled %@ : %@\n", wrap.name, wrap.identifier];
                [channels removeObject:wrap.identifier];
            } else {
                [message appendFormat:@"disabled %@ : %@\n", wrap.name, wrap.identifier];
            }
        }
        [message appendFormat:@"\nother channels %@", channels];
        
        [[UIPasteboard generalPasteboard] setValue:message forPasteboardType:(id)kUTTypeText];
        
        NSString *token = [WLNotificationCenter defaultCenter].pushToken.description;
        [[[UIAlertController alert:token message:message] action:@"ok".ls] show];
    }];
}

@end