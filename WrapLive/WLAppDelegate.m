//
//  WLAppDelegate.m
//  WrapLive
//
//  Created by Sergey Maximenko on 19.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLAppDelegate.h"
#import "WLInternetConnectionBroadcaster.h"
#import "WLSession.h"
#import "WLNotificationCenter.h"
#import "WLKeyboardBroadcaster.h"
#import <AviarySDK/AviarySDK.h>
#import "WLGestureBroadcaster.h"
#import "WLUploading+Extended.h"
#import "WLEntryManager.h"
#import <Crashlytics/Crashlytics.h>
#import "WLMenu.h"
#import "WLNavigation.h"
#import "NSPropertyListSerialization+Shorthand.h"

@interface WLAppDelegate ()

@end

@implementation WLAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    [UIWindow setMainWindow:self.window];
//
	[[WLInternetConnectionBroadcaster broadcaster] configure];
	[[WLKeyboardBroadcaster broadcaster] configure];
	[[WLNotificationCenter defaultCenter] configure];
//    [[WLGestureBroadcaster broadcaster] configure];
	
	[[WLNotificationCenter defaultCenter] handleRemoteNotification:[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey] success:nil failure:nil];
	
	[AFPhotoEditorController setAPIKey:@"a44aeda8d37b98e1" secret:@"94599065e4e4ee36"];
	[AFPhotoEditorController setPremiumAddOns:AFPhotoEditorPremiumAddOnWhiteLabel];
	
#ifndef DEBUG
    [Crashlytics startWithAPIKey:@"69a3b8800317dbff68b803e0aea860a48c73d998"];
#endif
    
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [WLUploading enqueueAutomaticUploading:^{
    }];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	[WLNotificationCenter setDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	NSLog(@"%@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [[WLNotificationCenter defaultCenter] handleRemoteNotification:userInfo success:^{
        if (completionHandler) completionHandler(UIBackgroundFetchResultNewData);
    } failure:^(NSError *error) {
        if (completionHandler) completionHandler(UIBackgroundFetchResultFailed);
    }];
}

@end
