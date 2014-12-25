//
//  WLAppDelegate.m
//  WrapLive
//
//  Created by Sergey Maximenko on 19.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLAppDelegate.h"
#import "WLNetwork.h"
#import "WLSession.h"
#import "WLNotificationCenter.h"
#import "WLKeyboard.h"
#import <AviarySDK/AviarySDK.h>
#import "WLGestureBroadcaster.h"
#import "WLUploading+Extended.h"
#import "WLEntryManager.h"
#import "WLMenu.h"
#import "WLNavigation.h"
#import "NSPropertyListSerialization+Shorthand.h"
#import "ALAssetsLibrary+Additions.h"
#import "UIColor+CustomColors.h"
#import "UIImage+Drawing.h"
#import "NSObject+NibAdditions.h"
#import "ALAssetsLibrary+Additions.h"
#import "WLAuthorizationRequest.h"
#import "WLRemoteObjectHandler.h"
#import "WLHomeViewController.h"
#import <iVersion/iVersion.h>

@interface WLAppDelegate () <iVersionDelegate>

@end

@implementation WLAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    iVersion *version = [iVersion sharedInstance];
    version.appStoreID = 879908578;
    version.updateAvailableTitle = @"New version of wrapLive is available";
    version.downloadButtonLabel = @"Update";
    version.remindButtonLabel = @"Not now";
    version.updatePriority = iVersionUpdatePriorityMedium;
    
    [NSValueTransformer setValueTransformer:[[WLPictureTransformer alloc] init] forName:@"pictureTransformer"];
    
    [UIWindow setMainWindow:self.window];
    [UIStoryboard setStoryboard:self.window.rootViewController.storyboard named:WLSignUpStoryboard];
	[[WLNetwork network] configure];
	[[WLKeyboard keyboard] configure];
	[[WLNotificationCenter defaultCenter] configure];
//    [[WLGestureBroadcaster broadcaster] configure];
	
	[[WLNotificationCenter defaultCenter] handleRemoteNotification:[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey] success:nil failure:nil];
	
	[AFPhotoEditorController setAPIKey:@"a44aeda8d37b98e1" secret:@"94599065e4e4ee36"];
	[AFPhotoEditorController setPremiumAddOns:AFPhotoEditorPremiumAddOnWhiteLabel];
    
#ifndef DEBUG
    [Crashlytics startWithAPIKey:@"69a3b8800317dbff68b803e0aea860a48c73d998"];
#endif
    
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    run_after(0.5f, ^{
        [[ALAssetsLibrary library] hasChanges:^(BOOL hasChanges) {
        }];
    });
        
	return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [WLUploading enqueueAutomaticUploading];
}


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	[WLNotificationCenter setDeviceToken:deviceToken];
}


- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    [url handleRemoteObject];
    return YES;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    [[WLNotificationCenter defaultCenter] handleRemoteNotification:userInfo success:^{
        if (completionHandler) completionHandler(UIBackgroundFetchResultNewData);
    } failure:^(NSError *error) {
        if (completionHandler) completionHandler(UIBackgroundFetchResultFailed);
    }];
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    if (![WLAuthorizationRequest authorized]) {
        completionHandler(UIBackgroundFetchResultFailed);
        return;
    }
    [[ALAssetsLibrary library] hasChanges:^(BOOL hasChanges) {
        if (hasChanges) {
            UILocalNotification *photoNotification = [[UILocalNotification alloc] init];
            photoNotification.alertBody = @"Got new photos? Upload them to your wraps now!";
            photoNotification.fireDate = [[NSDate date] dateByAddingTimeInterval:3];
            photoNotification.alertAction = @"Upload";
            photoNotification.repeatInterval = 0;
            photoNotification.userInfo = @{@"type":@"new_photos"};
            [application scheduleLocalNotification:photoNotification];
        }
        completionHandler(hasChanges ? UIBackgroundFetchResultNewData : UIBackgroundFetchResultNoData);
    }];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    if ([notification.userInfo[@"type"] isEqualToString:@"new_photos"]) {
        UINavigationController *navigationController = [UINavigationController mainNavigationController];
        WLHomeViewController *homeViewController = [navigationController.viewControllers firstObject];
        if ([homeViewController isKindOfClass:[WLHomeViewController class]]) {
            if (navigationController.topViewController != homeViewController) {
                [navigationController popToViewController:homeViewController animated:NO];
            }
            if (navigationController.presentedViewController) {
                [navigationController dismissViewControllerAnimated:NO completion:nil];
            }
            [homeViewController handleNewPhotosLocalNotification];
        }
    }
}

@end
