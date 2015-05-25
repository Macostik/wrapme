//
//  WLAppDelegate.m
//  WrapLive
//
//  Created by Sergey Maximenko on 19.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLAppDelegate.h"
#import "WLNotificationCenter.h"
#import "WLKeyboard.h"
#import "WLEntryManager.h"
#import "WLMenu.h"
#import "WLNavigationHelper.h"
#import "NSPropertyListSerialization+Shorthand.h"
#import "ALAssetsLibrary+Additions.h"
#import "NSObject+NibAdditions.h"
#import "ALAssetsLibrary+Additions.h"
#import "WLRemoteEntryHandler.h"
#import "WLHomeViewController.h"
#import "iVersion.h"
#import "WLLaunchScreenViewController.h"
#import "WLSignupFlowViewController.h"
#import "GAI.h"
#import <NewRelicAgent/NewRelic.h>
#import "WLToast.h"
#import "WLAddressBook.h"

@interface WLAppDelegate () <iVersionDelegate>

@end

@implementation WLAppDelegate

+ (void)initialize {
    WLInitializeConstants();
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:NSHomeDirectory()];
    
    [self initializeCrashlyticsAndLogging];
    
    [self initializeAPIManager];
    
    [self presentInitialViewController];
    
    [self initializeVersionTool];
    
	[[WLNetwork network] configure];
    [[WLNetwork network] setChangeReachabilityBlock:^(WLNetwork *network) {
        if (network.reachable) {
            if ([WLAuthorizationRequest authorized]) {
                [WLUploadingQueue start];
                [[WLAddressBook addressBook] updateCachedRecordsAfterFailure];
            } else {
                [[WLAuthorizationRequest signInRequest] send];
            }
        }
    }];
	[[WLKeyboard keyboard] configure];
	[[WLNotificationCenter defaultCenter] configure];
    [[WLNotificationCenter defaultCenter] handleRemoteNotification:[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey] success:^(WLNotification *notification) {
        if ([notification isKindOfClass:[WLEntryNotification class]]) {
            [[WLRemoteEntryHandler sharedHandler] presentEntryFromNotification:(id)notification];
        }
    } failure:nil];
    [[WLNotificationCenter defaultCenter] setGettingDeviceTokenBlock:^ (WLDataBlock gettingDeviceTokenCompletionBlock) {
        [self deviceToken:gettingDeviceTokenCompletionBlock];
    }];
    
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    run_after(0.5f, ^{
        [[ALAssetsLibrary library] hasChanges:^(BOOL hasChanges) {
        }];
    });
    
	return YES;
}

- (void)initializeAPIManager {
    WLAPIManager *manager = [WLAPIManager manager];
    [manager setUnauthorizedErrorBlock:^ (NSError *error) {
        WLLog(@"ERROR", @"redirection to welcome screen, sign in failed", error);
        [[UIStoryboard storyboardNamed:WLSignUpStoryboard] present:YES];
    }];
    
    [manager setShowErrorBlock:^ (NSError *error) {
        [WLToast showWithMessage:[error errorMessage]?:error.localizedDescription];
    }];
}

- (void)initializeCrashlyticsAndLogging {
    run_release(^{
        WLAPIEnvironment *environment = [WLAPIManager manager].environment;
        if ([environment.name isEqualToString:WLAPIEnvironmentProduction]) {
            [NewRelicAgent enableCrashReporting:YES];
            [NewRelicAgent startWithApplicationToken:@"AAd46869ec0b3558fb5890343d895b3acdd40ebaa8"];
            [[GAI sharedInstance] trackerWithTrackingId:@"UA-60538241-1"];
        } else if ([environment.name isEqualToString:WLAPIEnvironmentDevelopment]) {
            [NewRelicAgent startWithApplicationToken:@"AA55a96d2575ba2f5c16268eb56c94e91264d5236b"];
        } else {
            [NewRelicAgent enableCrashReporting:YES];
            [NewRelicAgent startWithApplicationToken:@"AA0d33ab51ad09e9b52f556149e4a7292c6d4c480c"];
        }
    });
}

- (void)initializeVersionTool {
    iVersion *version = [iVersion sharedInstance];
    version.appStoreID = WLConstants.appStoreID;
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
    
    void (^successBlock) (WLUser *user) = ^(WLUser *user) {
        if (user.isSignupCompleted) {
            [[UIStoryboard storyboardNamed:WLMainStoryboard] present:YES];
        } else {
            WLLog(@"INITIAL SIGN IN", @"sign up is not completed, redirecting to profile step", nil);
            UINavigationController *signupNavigationController = [[UIStoryboard storyboardNamed:WLSignUpStoryboard] instantiateInitialViewController];
            WLSignupFlowViewController *signupFlowViewController = [WLSignupFlowViewController instantiate:signupNavigationController.storyboard];
            signupFlowViewController.registrationNotCompleted = YES;
            signupNavigationController.viewControllers = @[signupFlowViewController];
            [UIWindow mainWindow].rootViewController = signupNavigationController;
        }
    };
    
    WLAuthorization* authorization = [WLAuthorization currentAuthorization];
    if ([authorization canAuthorize]) {
        [authorization signIn:successBlock failure:^(NSError *error) {
            WLUser *currentUser = [WLUser currentUser];
            if ([error isNetworkError] && currentUser) {
                successBlock(currentUser);
            } else {
                WLLog(@"INITIAL SIGN IN ERROR", @"couldn't sign in, so redirecting to welcome screen", nil);
                [[UIStoryboard storyboardNamed:WLSignUpStoryboard] present:YES];
            }
        }];
    } else {
        WLLog(@"INITIAL SIGN IN", @"no data for signing in", nil);
        [[UIStoryboard storyboardNamed:WLSignUpStoryboard] present:YES];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [WLUploadingQueue start];
}


static WLDataBlock deviceTokenCompletion = nil;

- (void)deviceToken:(WLDataBlock)completion {
    NSData* deviceToken = [WLSession deviceToken];
    if (deviceToken) {
        completion(deviceToken);
    } else {
        if (SystemVersionGreaterThanOrEqualTo8()) {
            UIMutableUserNotificationCategory *category = [[UIMutableUserNotificationCategory alloc] init];
            category.identifier = @"chat";
            UIMutableUserNotificationAction *action = [[UIMutableUserNotificationAction alloc] init];
            action.identifier = @"reply";
            action.title = @"Reply";
            action.activationMode = UIUserNotificationActivationModeForeground;
            action.authenticationRequired = YES;
            [category setActions:@[action] forContext:UIUserNotificationActionContextDefault];
            [[UIApplication sharedApplication] registerForRemoteNotifications];
            UIUserNotificationType types = UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
            UIUserNotificationSettings* settings = [UIUserNotificationSettings settingsForTypes:types categories:[NSSet setWithObject:category]];
            [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        } else {
            UIRemoteNotificationType type = UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound;
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:type];
        }
        deviceTokenCompletion = completion;
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [WLSession setDeviceToken:deviceToken];
    if (deviceTokenCompletion) {
        deviceTokenCompletion(deviceToken);
        deviceTokenCompletion = nil;
    }
}


- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [[WLRemoteEntryHandler sharedHandler] presentEntryFromURL:url failure:^(NSError *error) {
        [error show];
    }];
    return YES;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    BOOL inactive = application.applicationState == UIApplicationStateInactive;
    [[WLNotificationCenter defaultCenter] handleRemoteNotification:userInfo success:^(WLNotification *notification) {
        if ([notification isKindOfClass:[WLEntryNotification class]] && inactive) {
            [[WLRemoteEntryHandler sharedHandler] presentEntryFromNotification:(id)notification];
        }
        if (completionHandler) completionHandler(UIBackgroundFetchResultNewData);
    } failure:^(NSError *error) {
        if (completionHandler) completionHandler(UIBackgroundFetchResultFailed);
    }];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler {
    BOOL inactive = application.applicationState == UIApplicationStateInactive;
    [[WLNotificationCenter defaultCenter] handleRemoteNotification:userInfo success:^(WLNotification *notification) {
        if ([notification isKindOfClass:[WLEntryNotification class]] && inactive) {
            [[WLRemoteEntryHandler sharedHandler] presentEntryFromNotification:(id)notification];
        }
        if (completionHandler) completionHandler();
    } failure:^(NSError *error) {
        if (completionHandler) completionHandler();
    }];
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    if (![WLAuthorizationRequest authorized]) {
        completionHandler(UIBackgroundFetchResultFailed);
        return;
    }
    
    runDefaultQueuedOperations (@"background_fetch", ^(WLOperation *operation) {
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
            [operation finish:^{
                completionHandler(hasChanges ? UIBackgroundFetchResultNewData : UIBackgroundFetchResultNoData);
            }];
        }];
    }, ^(WLOperation *operation) {
        [WLUploadingQueue start:^{
            [operation finish:^{
                completionHandler(UIBackgroundFetchResultNoData);
            }];
        }];
    }, nil);
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
            [homeViewController openCameraAnimated:NO startFromGallery:YES showWrapPicker:YES];
        }
    }
}

- (void)application:(UIApplication *)application handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void (^)(NSDictionary *))reply {
    NSString *action = userInfo[@"action"];
    if (action.nonempty) {
        if ([action isEqualToString:@"authorization"]) {
            if ([[WLAuthorization currentAuthorization] canAuthorize]) {
                [[WLAuthorization currentAuthorization] setCurrent];
                [WLAPIManager saveEnvironmentName:[WLAPIManager manager].environment.name];
                if (reply) reply(@{@"success":@YES});
            } else {
                if (reply) reply(@{@"message":@"Please, launch wrapLive containing app for registration",@"success":@NO});
            }
            return;
        }
    }
    
    if (reply) reply(@{@"success":@NO});
}

@end
