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

@property (strong, nonatomic) WLBlock didBecomeActiveBlock;

@end

@implementation WLAppDelegate

+ (void)initialize {
    WLInitializeConstants();
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
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
            [[WLRemoteEntryHandler sharedHandler] presentEntryFromNotification:(id)notification failure:^(NSError *error) {
                [error show];
            }];
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
        UIStoryboard *storyboard = [UIStoryboard storyboardNamed:WLSignUpStoryboard];
        if ([UIWindow mainWindow].rootViewController.storyboard != storyboard) {
            [storyboard present:YES];
        }
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
    version.updateAvailableTitle = WLLS(@"new_version_is_available");
    version.downloadButtonLabel = WLLS(@"update");
    version.remindButtonLabel = WLLS(@"not_now");
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
    if (self.didBecomeActiveBlock) {
        self.didBecomeActiveBlock();
        self.didBecomeActiveBlock = nil;
    }
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
            action.title = WLLS(@"reply");
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

- (void)presentRemoteNotification:(WLEntryNotification *)notification {
    [[WLRemoteEntryHandler sharedHandler] presentEntryFromNotification:(id)notification failure:^(NSError *error) {
        [error show];
    }];
}

- (void)handleRemoteNotification:(NSDictionary*)userInfo completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    __weak typeof(self)weakSelf = self;
    BOOL probablyUserInteraction = [UIApplication sharedApplication].applicationState == UIApplicationStateInactive;
    [[WLNotificationCenter defaultCenter] handleRemoteNotification:userInfo success:^(WLNotification *notification) {
        if (notification.presentable) {
            UIApplicationState state = [UIApplication sharedApplication].applicationState;
            if (state == UIApplicationStateActive) {
                if (probablyUserInteraction) [weakSelf presentRemoteNotification:(id)notification];
                if (completionHandler) completionHandler(UIBackgroundFetchResultNewData);
            } else if (state == UIApplicationStateInactive) {
                [weakSelf setDidBecomeActiveBlock:^{
                    if (probablyUserInteraction) [weakSelf presentRemoteNotification:(id)notification];
                }];
                run_after(1.0f, ^{
                    weakSelf.didBecomeActiveBlock = nil;
                    if (completionHandler) completionHandler(UIBackgroundFetchResultNewData);
                });
            } else {
                if (completionHandler) completionHandler(UIBackgroundFetchResultNewData);
            }
        } else {
            if (completionHandler) completionHandler(UIBackgroundFetchResultNewData);
        }
    } failure:^(NSError *error) {
        if (completionHandler) completionHandler(UIBackgroundFetchResultFailed);
    }];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [self handleRemoteNotification:userInfo completionHandler:completionHandler];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler {
    [self handleRemoteNotification:userInfo completionHandler:^(UIBackgroundFetchResult result) {
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
                photoNotification.alertBody = WLLS(@"engagement_notification_alert");
                photoNotification.fireDate = [[NSDate date] dateByAddingTimeInterval:3];
                photoNotification.alertAction = WLLS(@"upload");
                photoNotification.repeatInterval = 0;
                photoNotification.userInfo = @{@"type":@"new_photos"};
                [application scheduleLocalNotification:photoNotification];
            }
            [operation finish:^{
                completionHandler(hasChanges ? UIBackgroundFetchResultNewData : UIBackgroundFetchResultNoData);
            }];
        }];
    }, ^(WLOperation *operation) {
        [WLUploadingQueue start];
        run_after(20, ^{
            [operation finish:^{
                completionHandler(UIBackgroundFetchResultNoData);
            }];
        });
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
    
    UIBackgroundTaskIdentifier task = [application beginBackgroundTaskWithExpirationHandler:^{
        if (reply) reply(@{@"success":@NO,@"message":@"Background task expired."});
    }];
    
    void (^completion) (NSDictionary*) = ^ (NSDictionary *replyInfo) {
        if (reply) reply(replyInfo);
        [application endBackgroundTask:task];
    };
    
    NSString *action = userInfo[@"action"];
    if (action.nonempty) {
        if ([action isEqualToString:@"authorization"]) {
            if ([[WLAuthorization currentAuthorization] canAuthorize]) {
                [[WLAuthorization currentAuthorization] setCurrent];
                [WLAPIManager saveEnvironmentName:[WLAPIManager manager].environment.name];
                completion(@{@"success":@YES});
            } else {
                completion(@{@"message":@"Please, launch wrapLive containing app for registration",@"success":@NO});
            }
        } else if ([action isEqualToString:@"post_chat_message"]) {
            NSString *wrapIdentifier = userInfo[WLWrapUIDKey];
            NSString *text = userInfo[@"text"];
            if ([WLWrap entryExists:wrapIdentifier]) {
                WLWrap *wrap = [WLWrap entry:wrapIdentifier];
                [wrap uploadMessage:text success:^(WLMessage *message) {
                    completion(@{@"success":@YES});
                } failure:^(NSError *error) {
                    completion(@{@"success":@NO,@"message":error.localizedDescription?:@""});
                }];
            } else {
                completion(@{@"success":@NO,@"message":@"Wrap isn't available."});
            }
        } else if ([action isEqualToString:@"post_comment"]) {
            NSString *candyIdentifier = userInfo[WLCandyUIDKey];
            NSString *text = userInfo[@"text"];
            if ([WLCandy entryExists:candyIdentifier]) {
                WLCandy *candy = [WLCandy entry:candyIdentifier];
                [candy uploadComment:text success:^(WLComment *comment) {
                    completion(@{@"success":@YES});
                } failure:^(NSError *error) {
                    completion(@{@"success":@NO,@"message":error.localizedDescription?:@""});
                }];
            } else {
                completion(@{@"success":@NO,@"message":@"Photo isn't available."});
            }
        } else if ([action isEqualToString:@"fetch_notification"]) {
            
            [[WLNotificationCenter defaultCenter] handleRemoteNotification:userInfo[@"notification"] success:^(WLNotification *notification) {
                if ([notification isKindOfClass:[WLEntryNotification class]]) {
                    NSDictionary *entry = [[(WLEntryNotification*)notification targetEntry] dictionaryRepresentation];
                    if (entry) {
                        run_after(0.5, ^{
                            completion(@{@"success":@YES,@"entry":entry});
                        });
                    } else {
                        completion(@{@"success":@NO,@"message":@"No data."});
                    }
                } else {
                    completion(@{@"success":@NO,@"message":@"This notification type isn't supperted."});
                }
            } failure:^(NSError *error) {
                completion(@{@"success":@NO,@"message":error.localizedDescription?:@""});
            }];
        }
    } else {
        completion(@{@"success":@NO,@"message":@"No action specified."});
    }
}

@end
