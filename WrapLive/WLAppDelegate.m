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
#import "iVersion.h"
#import "WLLaunchScreenViewController.h"

@interface WLAppDelegate () <iVersionDelegate>

@end

@implementation WLAppDelegate

+ (void)initialize {
    WLInitializeConstants();
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [self initializeCrashlyticsAndLogging];
    
    [NSValueTransformer setValueTransformer:[[WLPictureTransformer alloc] init] forName:@"pictureTransformer"];
    
    [self presentInitialViewController];
    
    [self initializeVersionTool];
    
	[[WLNetwork network] configure];
	[[WLKeyboard keyboard] configure];
	[[WLNotificationCenter defaultCenter] configure];
	[[WLNotificationCenter defaultCenter] handleRemoteNotification:[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey] success:nil failure:nil];
    
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    run_after(0.5f, ^{
        [[ALAssetsLibrary library] hasChanges:^(BOOL hasChanges) {
        }];
    });
    
	return YES;
}

- (void)initializeCrashlyticsAndLogging {
    [LELog sharedInstance].token = @"e9e259b1-98e6-41b5-b530-d89d1f5af01d";
    run_release(^{
        [Crashlytics startWithAPIKey:@"69a3b8800317dbff68b803e0aea860a48c73d998"];
        
        void (^notificationBlock) (NSNotification *n) = ^ (NSNotification *n) {
            [Crashlytics setIntValue:[UIApplication sharedApplication].applicationState forKey:@"applicationState"];
        };
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:nil usingBlock:notificationBlock];
        [center addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:nil usingBlock:notificationBlock];
        [center addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:nil usingBlock:notificationBlock];
        [center addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:notificationBlock];
    });
}

- (void)initializeVersionTool {
    iVersion *version = [iVersion sharedInstance];
    version.appStoreID = 879908578;
    version.updateAvailableTitle = WLLS(@"New version of wrapLive is available");
    version.downloadButtonLabel = WLLS(@"Update");
    version.remindButtonLabel = WLLS(@"Not now");
    version.updatePriority = iVersionUpdatePriorityMedium;
}

- (void)presentInitialViewController {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window makeKeyAndVisible];
    
    [UIWindow setMainWindow:self.window];
    
    self.window.rootViewController = [[WLLaunchScreenViewController alloc] init];
    NSString* storedVersion = [WLSession appVersion];
    if (!storedVersion || [storedVersion compare:@"2.0" options:NSNumericSearch] == NSOrderedAscending) {
        [WLSession clear];
    }
    [WLSession setCurrentAppVersion];
    
    WLAuthorization* authorization = [WLAuthorization currentAuthorization];
    if ([authorization canAuthorize]) {
        [authorization signIn:^(WLUser *user) {
            [[UIStoryboard storyboardNamed:WLMainStoryboard] present:YES];
        } failure:^(NSError *error) {
            if ([error isNetworkError]) {
                [[UIStoryboard storyboardNamed:WLMainStoryboard] present:YES];
            } else {
                [[UIStoryboard storyboardNamed:WLSignUpStoryboard] present:YES];
            }
        }];
    } else {
        [[UIStoryboard storyboardNamed:WLSignUpStoryboard] present:YES];
    }
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
            photoNotification.alertBody = WLLS(@"Got new photos? Upload them to your wraps now!");
            photoNotification.fireDate = [[NSDate date] dateByAddingTimeInterval:3];
            photoNotification.alertAction = WLLS(@"Upload");
            photoNotification.repeatInterval = 0;
            photoNotification.userInfo = @{@"type":@"new_photos"};
            [application scheduleLocalNotification:photoNotification];
        }
        completionHandler(hasChanges ? UIBackgroundFetchResultNewData : UIBackgroundFetchResultNoData);
    }];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    if ([notification.userInfo[@"type"] isEqualToString:@"new_photos"] && application.applicationState != UIApplicationStateActive) {
        UINavigationController *navigationController = [UINavigationController mainNavigationController];
        WLHomeViewController *homeViewController = [navigationController.viewControllers firstObject];
        if ([homeViewController isKindOfClass:[WLHomeViewController class]]) {
            if (navigationController.topViewController != homeViewController) {
                [navigationController popToViewController:homeViewController animated:NO];
            }
            if (navigationController.presentedViewController) {
                [navigationController dismissViewControllerAnimated:NO completion:nil];
            }
            [homeViewController openCameraAnimated:NO startFromGallery:YES];
        }
    }
}

@end
