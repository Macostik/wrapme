//
//  WLAppDelegate.m
//  meWrap
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
#import "WLEntryPresenter.h"
#import "WLWrapViewController.h"
#import "CocoaLumberjack.h"
#import "WLAuthorizationRequest.h"
#import "WLUploadingQueue.h"
#import "WLEntry+WLUploadingQueue.h"
#import "WLNetwork.h"
#import <AWSCore/AWSCore.h>
#import "WLExtensionManager.h"

@import Photos;

@interface WLAppDelegate () <iVersionDelegate /*PHPhotoLibraryChangeObserver*/>

@property (nonatomic) BOOL versionChanged;

@end

@implementation WLAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [self registerUserNotificationSettings];
    
    [self initializeCrashlyticsAndLogging];
    
    [self initializeAPIManager];
    
    [self initializerAWS];
    
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
	
    NSDictionary *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    [[WLNotificationCenter defaultCenter] handleRemoteNotification:notification success:^(id object) {
        if (object) {
            [self presentNotification:object];
        }
    } failure:^(NSError *error) {
        [error show];
    }];
    
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
	return YES;
}

- (void)initializeAPIManager {
    [WLAPIRequest setUnauthorizedErrorBlock:^ (WLAPIRequest *request, NSError *error) {
        UIStoryboard *storyboard = [UIStoryboard storyboardNamed:WLSignUpStoryboard];
        if ([UIWindow mainWindow].rootViewController.storyboard != storyboard) {
            UIViewController *rootViewController = [UIWindow mainWindow].rootViewController.presentedViewController ? : [UIWindow mainWindow].rootViewController;
            UIView *topView = rootViewController.view;
            topView.userInteractionEnabled = YES;
            [UIAlertController confirmRedirectingToSignUp:^{
                WLLog(@"ERROR - redirection to welcome screen, sign in failed: %@", error);
                [[WLNotificationCenter defaultCenter] clear];
                [WLSession clear];
                [storyboard present:YES];
                topView.userInteractionEnabled = YES;
            } tryAgain:^{
                topView.userInteractionEnabled = NO;
                WLObjectBlock successBlock = request.successBlock;
                WLFailureBlock failureBlock = request.failureBlock;
                [request send:^(id object) {
                    if (successBlock) successBlock(object);
                    topView.userInteractionEnabled = YES;
                } failure:^(NSError *error) {
                     topView.userInteractionEnabled = YES;
                    if (failureBlock) failureBlock(error);
                }];
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

- (void)initializerAWS {
    AWSStaticCredentialsProvider *credentialsProvider = [[AWSStaticCredentialsProvider alloc] initWithAccessKey:@"AKIAIPEMEBV7F4GN2FVA"
                                                                                                      secretKey:@"hIuguWj0bm9Pxgg2CREG7zWcE14EKaeTE7adXB7f"];
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSWest2 credentialsProvider:credentialsProvider];
    AWSServiceManager.defaultServiceManager.defaultServiceConfiguration = configuration;
}

- (void)createWindow {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window makeKeyAndVisible];
    [UIWindow setMainWindow:self.window];
    
    NSString *storedVersion = WLSession.appVersion;
    NSString *currentVersion = [NSBundle mainBundle].buildVersion;
    
    if (!storedVersion || [storedVersion compare:@"2.0" options:NSNumericSearch] == NSOrderedAscending) {
        [WLSession clear];
    }
    
    if (![storedVersion isEqualToString:currentVersion]) {
        self.versionChanged = YES;
        WLSession.appVersion = currentVersion;
    }
}

- (void)presentInitialViewController {
    void (^successBlock) (WLUser *user) = ^(WLUser *user) {
        if (user.isSignupCompleted) {
            [[UIStoryboard storyboardNamed:WLMainStoryboard] present:YES];
        } else {
            WLLog(@"INITIAL SIGN IN - sign up is not completed, redirecting to profile step");
            UINavigationController *signupNavigationController = [[UIStoryboard storyboardNamed:WLSignUpStoryboard] instantiateInitialViewController];
            WLSignupFlowViewController *signupFlowViewController = [WLSignupFlowViewController instantiate:signupNavigationController.storyboard];
            signupFlowViewController.registrationNotCompleted = YES;
            signupNavigationController.viewControllers = @[signupFlowViewController];
            [UIWindow mainWindow].rootViewController = signupNavigationController;
        }
    };
    
    WLAuthorization* authorization = [WLAuthorization currentAuthorization];
    if ([authorization canAuthorize]) {
        if (!self.versionChanged && ![WLAuthorizationRequest requiresSignIn]) {
            WLUser *currentUser = [WLUser currentUser];
            if (currentUser) {
                successBlock(currentUser);
                [currentUser notifyOnAddition];
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
                [UIAlertController confirmRedirectingToSignUp:^{
                    WLLog(@"INITIAL SIGN IN ERROR - couldn't sign in, so redirecting to welcome screen");
                    [[UIStoryboard storyboardNamed:WLSignUpStoryboard] present:YES];
                } tryAgain:^{
                    [weakSelf presentInitialViewController];
                }];
            }
        }];
    } else {
        WLLog(@"INITIAL SIGN IN - no data for signing in");
        [[UIStoryboard storyboardNamed:WLSignUpStoryboard] present:YES];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [WLUploadingQueue start];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[WLNotificationCenter defaultCenter] handleDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    __block void (^completion)(UIBackgroundFetchResult) = completionHandler;
    
    UIApplicationState state = [UIApplication sharedApplication].applicationState;
    if (state == UIApplicationStateActive) {
        return;
    }
    BOOL presentable = state == UIApplicationStateInactive;
    [[WLNotificationCenter defaultCenter] handleRemoteNotification:userInfo success:^(WLNotification *notification) {
        if (presentable) {
            [self presentNotification:notification];
        }
        if (completion) {
            completion(UIBackgroundFetchResultNewData);
            completion = nil;
        }
    } failure:^(NSError *error) {
        if (completion) {
            completion(UIBackgroundFetchResultFailed);
            completion = nil;
        }
    }];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler {
    
    __block void (^completion)(UIBackgroundFetchResult) = completionHandler;
    
    [[WLNotificationCenter defaultCenter] handleRemoteNotification:userInfo success:^(WLNotification *notification) {
        [self presentNotification:notification handleActionWithIdentifier:identifier];
        if (completion) {
            completion(UIBackgroundFetchResultNewData);
            completion = nil;
        }
    } failure:^(NSError *error) {
        if (completion) {
            completion(UIBackgroundFetchResultFailed);
            completion = nil;
        }
    }];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [[WLRemoteEntryHandler sharedHandler] presentEntryFromURL:url failure:^(NSError *error) {
        [error show];
    }];
    return YES;
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    __block void (^completion)(UIBackgroundFetchResult) = completionHandler;
    
    if (![WLAuthorizationRequest authorized]) {
        if (completion) {
            completion(UIBackgroundFetchResultFailed);
            completion = nil;
        }
        return;
    }
    [WLUploadingQueue start];
    run_after(20, ^{
        if (completion) {
            completion(UIBackgroundFetchResultNewData);
            completion = nil;
        }
    });
}

- (void)presentNotification:(WLNotification *)notification {
    [self presentNotification:notification handleActionWithIdentifier:nil];
}

- (void)presentNotification:(WLNotification *)notification handleActionWithIdentifier:(NSString *)identifier {
    
    WLNotificationType type = notification.type;
    if (type == WLNotificationUpdateAvailable) {
        [[UIApplication sharedApplication] openURL:[[NSString stringWithFormat:@"itms-apps://itunes.apple.com/app/id%@",@(WLConstants.appStoreID)] URL]];
    } else {
        WLEntry *entry = notification.entry;
        if (entry) {
            [[WLRemoteEntryHandler sharedHandler] presentEntry:entry];
            if ([identifier isEqualToString:@"reply"]) {
                id wrapViewController = [entry viewControllerWithNavigationController:[UINavigationController mainNavigationController]];
                [wrapViewController setShowKeyboard:YES];
            }
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
    [WLExtensionManager performRequest:request completionHandler:completion];
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

@end
