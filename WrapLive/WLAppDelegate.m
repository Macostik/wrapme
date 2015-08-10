//
//  WLAppDelegate.m
//  moji
//
//  Created by Ravenpod on 19.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
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
#import "WLEntryNotification.h"
#import "WLAlertView.h"
#import "UIFont+CustomFonts.h"

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
    
    [[WLNotificationCenter defaultCenter] configure];
    
    [self createWindow];
    
    [self presentInitialViewController];
    
    [self initializeVersionTool];
    
	[[WLNetwork network] configure];
    [[WLNetwork network] setChangeReachabilityBlock:^(WLNetwork *network) {
        if (network.reachable) {
            if ([WLAuthorizationRequest authorized]) {
                [WLUploadingQueue start];
                [[WLAddressBook addressBook] updateCachedRecordsAfterFailure];
            } else {
                [[WLAuthorizationRequest signIn] send];
            }
        }
    }];
	[[WLKeyboard keyboard] configure];
	
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
    
    runUnaryQueuedOperation(@"background_fetch", ^(WLOperation *operation) {
        run_after(0.5f, ^{
            [[ALAssetsLibrary library] hasChanges:^(BOOL hasChanges) {
                [operation finish];
            }];
        });
    });
    
	return YES;
}

- (void)initializeAPIManager {
    [WLAPIRequest setUnauthorizedErrorBlock:^ (WLAPIRequest *request, NSError *error) {
        UIStoryboard *storyboard = [UIStoryboard storyboardNamed:WLSignUpStoryboard];
        if ([UIWindow mainWindow].rootViewController.storyboard != storyboard) {
            [WLAlertView confirmRedirectingToSignUp:^{
                WLLog(@"ERROR", @"redirection to welcome screen, sign in failed", error);
                [storyboard present:YES];
            } tryAgain:^{
                [request send];
            }];
        }
    }];
    [NSError setShowingBlock:^ (NSError *error) {
        [WLToast showWithMessage:[error errorMessage]?:error.localizedDescription];
    }];
}

- (void)initializeCrashlyticsAndLogging {
    run_release(^{
        [NewRelicAgent enableCrashReporting:YES];
        WLAPIEnvironment *environment = [WLAPIEnvironment currentEnvironment];
        if ([environment.name isEqualToString:WLAPIEnvironmentProduction]) {
            [NewRelicAgent startWithApplicationToken:@"AAd46869ec0b3558fb5890343d895b3acdd40ebaa8"];
            [[GAI sharedInstance] trackerWithTrackingId:@"UA-60538241-1"];
        } else {
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

- (void)createWindow {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window makeKeyAndVisible];
    [UIWindow setMainWindow:self.window];
    
    NSString* storedVersion = [WLSession appVersion];
    if (!storedVersion || [storedVersion compare:@"2.0" options:NSNumericSearch] == NSOrderedAscending) {
        [WLSession clear];
    }
    [WLSession setCurrentAppVersion];
}

- (void)presentInitialViewController {
    
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
        if ([WLAuthorizationRequest authorized]) {
            WLUser *currentUser = [WLUser currentUser];
            if (currentUser) {
                successBlock(currentUser);
                return;
            }
        }
        self.window.rootViewController = [[WLLaunchScreenViewController alloc] init];
        __weak typeof(self)weakSelf = self;
        [authorization signIn:successBlock failure:^(NSError *error) {
            WLUser *currentUser = [WLUser currentUser];
            if ([error isNetworkError] && currentUser) {
                successBlock(currentUser);
            } else {
                [WLAlertView confirmRedirectingToSignUp:^{
                    WLLog(@"INITIAL SIGN IN ERROR", @"couldn't sign in, so redirecting to welcome screen", nil);
                    [[UIStoryboard storyboardNamed:WLSignUpStoryboard] present:YES];
                } tryAgain:^{
                    [weakSelf presentInitialViewController];
                }];
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
    __block void (^blockCompletion)(UIBackgroundFetchResult) = completionHandler;
    
    UIBackgroundTaskIdentifier task = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if (blockCompletion) blockCompletion(UIBackgroundFetchResultFailed);
        blockCompletion = nil;
    }];
    
    void (^validatedCompletion)(UIBackgroundFetchResult) = ^ (UIBackgroundFetchResult result) {
        if (blockCompletion) blockCompletion(result);
        blockCompletion = nil;
        [[UIApplication sharedApplication] endBackgroundTask:task];
    };
    
    BOOL probablyUserInteraction = [UIApplication sharedApplication].applicationState == UIApplicationStateInactive;
    [[WLNotificationCenter defaultCenter] handleRemoteNotification:userInfo success:^(WLNotification *notification) {
        if (notification.presentable) {
            UIApplicationState state = [UIApplication sharedApplication].applicationState;
            if (state == UIApplicationStateActive) {
                if (probablyUserInteraction) [weakSelf presentRemoteNotification:(id)notification];
                validatedCompletion(UIBackgroundFetchResultNewData);
            } else if (state == UIApplicationStateInactive) {
                [weakSelf setDidBecomeActiveBlock:^{
                    if (probablyUserInteraction) [weakSelf presentRemoteNotification:(id)notification];
                }];
                run_after(1.0f, ^{
                    weakSelf.didBecomeActiveBlock = nil;
                    validatedCompletion(UIBackgroundFetchResultNewData);
                });
            } else {
                validatedCompletion(UIBackgroundFetchResultNewData);
            }
        } else {
            validatedCompletion(UIBackgroundFetchResultNewData);
        }
    } failure:^(NSError *error) {
        validatedCompletion(UIBackgroundFetchResultFailed);
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
    
    runUnaryQueuedOperations(@"background_fetch", ^(WLOperation *operation) {
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
    
    __block BOOL completed = NO;
    UIBackgroundTaskIdentifier task = [application beginBackgroundTaskWithExpirationHandler:^{
        if (!completed && reply) reply([[WLExtensionResponse failureWithMessage:@"Background task expired."] serialize]);
        completed = YES;
    }];
    
    void (^completion) (WLExtensionResponse*) = ^ (WLExtensionResponse *response) {
        if (!completed && reply) reply([response serialize]);
        completed = YES;
        [application endBackgroundTask:task];
    };
    
    WLExtensionRequest *request = [WLExtensionRequest deserialize:userInfo];
    if (request.action.nonempty) {
        if ([request.action isEqualToString:@"authorization"]) {
            if ([[WLAuthorization currentAuthorization] canAuthorize]) {
                [[WLAuthorization currentAuthorization] setCurrent];
                completion([WLExtensionResponse success]);
            } else {
                completion([WLExtensionResponse failureWithMessage:@"Please, launch MOJI containing app for registration"]);
            }
        } else if ([request.action isEqualToString:@"post_chat_message"]) {
            NSString *wrapIdentifier = request.userInfo[WLWrapUIDKey];
            NSString *text = request.userInfo[@"text"];
            if ([WLWrap entryExists:wrapIdentifier]) {
                WLWrap *wrap = [WLWrap entry:wrapIdentifier];
                [wrap uploadMessage:text success:^(WLMessage *message) {
                    completion([WLExtensionResponse success]);
                } failure:^(NSError *error) {
                    completion([WLExtensionResponse failureWithMessage:error.localizedDescription]);
                }];
            } else {
                completion([WLExtensionResponse failureWithMessage:@"Moji isn't available."]);
            }
        } else if ([request.action isEqualToString:@"post_comment"]) {
            NSString *candyIdentifier = request.userInfo[WLCandyUIDKey];
            NSString *text = request.userInfo[@"text"];
            if ([WLCandy entryExists:candyIdentifier]) {
                WLCandy *candy = [WLCandy entry:candyIdentifier];
                [candy uploadComment:text success:^(WLComment *comment) {
                    completion([WLExtensionResponse success]);
                } failure:^(NSError *error) {
                    completion([WLExtensionResponse failureWithMessage:error.localizedDescription]);
                }];
            } else {
                completion([WLExtensionResponse failureWithMessage:@"Photo isn't available."]);
            }
        } else if ([request.action isEqualToString:@"fetch_notification"]) {
            
            [[WLNotificationCenter defaultCenter] handleRemoteNotification:request.userInfo[@"notification"] success:^(WLNotification *notification) {
                if ([notification isKindOfClass:[WLEntryNotification class]]) {
                    NSDictionary *entry = [[(WLEntryNotification*)notification targetEntry] dictionaryRepresentation];
                    if (entry) {
                        run_after(0.5, ^{
                            completion([WLExtensionResponse successWithUserInfo:@{@"entry":entry}]);
                        });
                    } else {
                        completion([WLExtensionResponse failureWithMessage:@"No data."]);
                    }
                } else {
                    completion([WLExtensionResponse failureWithMessage:@"This notification type isn't supported."]);
                }
            } failure:^(NSError *error) {
                completion([WLExtensionResponse failureWithMessage:error.localizedDescription]);
            }];
        }
    } else {
        completion([WLExtensionResponse failureWithMessage:@"No action specified."]);
    }
}

@end
