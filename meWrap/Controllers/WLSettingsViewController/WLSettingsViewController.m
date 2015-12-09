//
//  WLSettingsViewController.m
//  meWrap
//
//  Created by Ravenpod on 11/21/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLSettingsViewController.h"
#import "WLToast.h"
#import "WLNotificationCenter.h"

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
        [[RunQueue fetchQueue] cancelAll];
        [[WLAPIManager manager].operationQueue cancelAllOperations];
        [[WLNotificationCenter defaultCenter] clear];
        [[NSUserDefaults standardUserDefaults] clear];
        [[UIStoryboard signUp] present:YES];
        [RecentUpdateList sharedList].updates = nil;
    }] show];
}

- (IBAction)addDemoImages:(id)sender {
    [self addDemoImageWithCount:5];
    [WLToast showWithMessage:@"5 demo images will be added to Photos"];
}

- (IBAction)cleanCache:(id)sender {
    [[RunQueue fetchQueue] cancelAll];
    [[WLAPIManager manager].operationQueue cancelAllOperations];
    __weak User *currentUser = [User currentUser];
    __weak EntryContext *context = EntryContext.sharedContext;
    for (Wrap *wrap in [Wrap entries]) {
        [context uncacheEntry:wrap];
        [context deleteObject:wrap];
    }
    for (User *user in [User entries]) {
        if (user != currentUser) {
            [context uncacheEntry:user];
            [context deleteObject:user];
        }
    }
    [context save:NULL];
    currentUser.wraps = [NSSet set];
    [[ImageCache defaultCache] clear];
    [[ImageCache uploadingCache] clear];
    [[InMemoryImageCache instance] removeAllObjects];
    [[UIStoryboard main] present:YES];
}

- (void)addDemoImageWithCount:(NSUInteger)count {
    if (count == 0) return;
    
    NSString* stringUrl = count % 2 == 0 ? @"https://placeimg.com/640/1136/any" : @"https://placeimg.com/1136/640/any";
    __weak __typeof(self)weakSelf = self;
    [PHPhotoLibrary addImageAtFileUrl:[stringUrl URL] collectionTitle:[Constants albumName] success:^{
        [weakSelf addDemoImageWithCount:count - 1];
    } failure:^(NSError *error) {
        
    }];
}

@end