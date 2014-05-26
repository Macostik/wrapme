//
//  WLAppDelegate.m
//  WrapLive
//
//  Created by Sergey Maximenko on 19.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLAppDelegate.h"
#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDASLLogger.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import "WLInternetConnectionBroadcaster.h"
#import "WLSession.h"
#import "WLNotificationBroadcaster.h"
#import "WLKeyboardBroadcaster.h"
#import <AviarySDK/AviarySDK.h>

@interface WLAppDelegate ()

@end

@implementation WLAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
	[DDLog addLogger:[DDASLLogger sharedInstance]];
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
//	
	[application registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
	[[WLInternetConnectionBroadcaster broadcaster] configure];
	[[WLKeyboardBroadcaster broadcaster] configure];
	[[WLNotificationBroadcaster broadcaster] configure];
	
	[[WLNotificationBroadcaster broadcaster] handleRemoteNotification:[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]];
	
	[AFPhotoEditorController setAPIKey:@"400a0c21d96226e6" secret:@"8fe86ddd518dc34b"];
	
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
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	NSLog(@"deviceToken %@", deviceToken);
	[WLSession setDeviceToken:deviceToken];
	[WLNotificationBroadcaster enablePushNotificationsInSubscribedChannels:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	NSLog(@"%@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	if (application.applicationState != UIApplicationStateActive) {
		[[WLNotificationBroadcaster broadcaster] handleRemoteNotification:userInfo];
	}
}

@end
