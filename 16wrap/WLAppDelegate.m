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
#import "NSObject+NibAdditions.h"
#import "WLRemoteEntryHandler.h"
#import "WLHomeViewController.h"
#import "iVersion.h"
#import "WLSignupFlowViewController.h"
#import "GAI.h"
#import <NewRelicAgent/NewRelic.h>
#import "WLToast.h"
#import "WLAddressBook.h"
#import "WLNotification.h"
#import "WLAlertView.h"
#import "UIFont+CustomFonts.h"
#import "WLEntryPresenter.h"
#import "WLWrapViewController.h"

@import Photos;

@interface WLAppDelegate () <iVersionDelegate, PHPhotoLibraryChangeObserver>

@end

@implementation WLAppDelegate

static PHFetchResult *fetchResult;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
     [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    
    [self registerUserNotificationSettings];
    
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
	
    UILocalNotification *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (notification) {
        [self presentNotification:notification.userInfo];
    }
    
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    fetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeMoment subtype:PHAssetCollectionSubtypeAny options:nil];

	return YES;
}

- (void)initializeAPIManager {
    [WLAPIRequest setUnauthorizedErrorBlock:^ (WLAPIRequest *request, NSError *error) {
        UIStoryboard *storyboard = [UIStoryboard storyboardNamed:WLSignUpStoryboard];
        if ([UIWindow mainWindow].rootViewController.storyboard != storyboard) {
            [WLAlertView confirmRedirectingToSignUp:^{
                WLLog(@"ERROR", @"redirection to welcome screen, sign in failed", error);
                [[WLNotificationCenter defaultCenter] clear];
                [WLSession clear];
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
        self.window.rootViewController = [[UIViewController alloc] initWithNibName:@"WLLaunchScreenViewController" bundle:nil];
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
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [[WLRemoteEntryHandler sharedHandler] presentEntryFromURL:url failure:^(NSError *error) {
        [error show];
    }];
    return YES;
}

static BOOL hasChanges;

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    if (![WLAuthorizationRequest authorized]) {
        completionHandler(UIBackgroundFetchResultFailed);
        return;
    }
    NSLog(@"performFetchWithCompletionHandler");
    runUnaryQueuedOperation(@"background_fetch", ^(WLOperation *operation) {
        [WLUploadingQueue start];
        run_after(20, ^{
            [operation finish:^{
                completionHandler(hasChanges ? UIBackgroundFetchResultNewData : UIBackgroundFetchResultNoData);
                hasChanges = NO;
            }];
        });
    });
}

- (void)presentNotification:(NSDictionary *)notification {
    WLNotificationType type = [notification integerForKey:@"type"];
    if (type == WLNotificationUpdateAvailable) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"itms-apps://itunes.apple.com/app/id%@",@(WLConstants.appStoreID)]]];
    } else if (type == WLNotificationEngagement) {
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
    } else {
        WLEntry *entry = [WLEntry entryFromDictionaryRepresentation:[notification dictionaryForKey:@"entry"]];
        [[WLRemoteEntryHandler sharedHandler] presentEntry:entry];
    }
}

- (void)presentNotification:(NSDictionary *)notification handleActionWithIdentifier:(NSString *)identifier {
    if ([identifier isEqualToString:@"reply"]) {
        WLEntry *entry = [WLEntry entryFromDictionaryRepresentation:[notification dictionaryForKey:@"entry"]];
        [[WLRemoteEntryHandler sharedHandler] presentEntry:entry];
        id wrapViewController = [entry viewControllerWithNavigationController:[UINavigationController mainNavigationController]];
        [wrapViewController setShowKeyboard:YES];
    } else {
        [self presentNotification:notification];
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    UIApplicationState state = [UIApplication sharedApplication].applicationState;
    if (state == UIApplicationStateActive) {
        return;
    }
    BOOL presentable = state == UIApplicationStateInactive;
    [[WLNotificationCenter defaultCenter] handleRemoteNotification:userInfo success:^(WLNotification *notification) {
        if (presentable) {
            NSDictionary *entry = [notification.entry dictionaryRepresentation];
            if (entry) {
                [self presentNotification:@{@"type":@(notification.type),@"entry":entry}];
            }
        }
        completionHandler(UIBackgroundFetchResultNewData);
    } failure:^(NSError *error) {
        completionHandler(UIBackgroundFetchResultFailed);
    }];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler {
    [[WLNotificationCenter defaultCenter] handleRemoteNotification:userInfo success:^(WLNotification *notification) {
        NSDictionary *entry = [notification.entry dictionaryRepresentation];
        if (entry) {
            [self presentNotification:@{@"type":@(notification.type),@"entry":entry}];
        }
        completionHandler(UIBackgroundFetchResultNewData);
    } failure:^(NSError *error) {
        completionHandler(UIBackgroundFetchResultFailed);
    }];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    [self presentNotification:notification.userInfo];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void (^)())completionHandler {
    [self presentNotification:notification.userInfo handleActionWithIdentifier:identifier];
    if (completionHandler) completionHandler();
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
                completion([WLExtensionResponse failureWithMessage:@"Please, launch 16wrap containing app for registration"]);
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
                completion([WLExtensionResponse failureWithMessage:@"Wrap isn't available."]);
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
        }
    } else {
        completion([WLExtensionResponse failureWithMessage:@"No action specified."]);
    }
}

- (void)registerUserNotificationSettings {
    UIMutableUserNotificationCategory *category = [[UIMutableUserNotificationCategory alloc] init];
    category.identifier = @"chat";
    UIMutableUserNotificationAction *action = [[UIMutableUserNotificationAction alloc] init];
    action.identifier = @"reply";
    action.title = WLLS(@"reply");
    action.activationMode = UIUserNotificationActivationModeForeground;
    action.authenticationRequired = YES;
    [category setActions:@[action] forContext:UIUserNotificationActionContextDefault];
    UIUserNotificationType types = UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
    UIUserNotificationSettings* settings = [UIUserNotificationSettings settingsForTypes:types categories:[NSSet setWithObject:category]];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    run_in_main_queue(^{
        PHFetchResultChangeDetails *changeDetails = [changeInstance changeDetailsForFetchResult:fetchResult];
        if (changeDetails && changeDetails.insertedObjects) {
            hasChanges = YES;
            UILocalNotification *photoNotification = [[UILocalNotification alloc] init];
            photoNotification.alertBody = WLLS(@"engagement_notification_alert");
            photoNotification.alertAction = WLLS(@"upload");
            photoNotification.repeatInterval = 0;
            photoNotification.userInfo = @{@"type":@(WLNotificationEngagement)};
            [[UIApplication sharedApplication] presentLocalNotificationNow:photoNotification];
        }
    });
}

@end
