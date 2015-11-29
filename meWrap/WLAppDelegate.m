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
#import "WLHomeViewController.h"
#import "iVersion.h"
#import "WLSignupFlowViewController.h"
#import "GAI.h"
#import <NewRelicAgent/NewRelic.h>
#import "WLToast.h"
#import "WLAddressBook.h"
#import "WLNotification.h"
#import "WLWrapViewController.h"
#import "CocoaLumberjack.h"
#import "WLAuthorizationRequest.h"
#import "WLUploadingQueue.h"
#import "WLNetwork.h"
#import <AWSCore/AWSCore.h>
@import WatchConnectivity;

@interface WLAppDelegate () <iVersionDelegate, WCSessionDelegate>

@property (nonatomic) BOOL versionChanged;

@end

@implementation WLAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    WLLog(@"meWrap - API environment initialized: %@", [Environment currentEnvironment]);
    
    [NSKeyedUnarchiver setClass:[Authorization class] forClassName:@"WLAuthorization"];
    
    [self registerUserNotificationSettings];
    
    [self initializeCrashlyticsAndLogging];
    
    [self initializeAPIManager];
    
    [self initializerAWS];
    
    [[WLNotificationCenter defaultCenter] configure];
    
    [self createWindow];
    
    [self presentInitialViewController];
    
    [self initializeVersionTool];
    
	[[WLNetwork sharedNetwork] configure];
    [[WLNetwork sharedNetwork] setChangeReachabilityBlock:^(WLNetwork *network) {
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
    
    if ([WCSession isSupported]) {
        WCSession *session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
    }
    
	return YES;
}

- (void)initializeAPIManager {
    [WLAPIRequest setUnauthorizedErrorBlock:^ (WLAPIRequest *request, NSError *error) {
        WLLog(@"UNAUTHORIZED_ERROR: %@", error);
        UIStoryboard *storyboard = [UIStoryboard signUp];
        UIWindow *window = [UIWindow mainWindow];
        if (window.rootViewController.storyboard != storyboard) {
            UIView *topView = (window.rootViewController.presentedViewController ? : window.rootViewController).view;
            topView.userInteractionEnabled = YES;
            [UIAlertController confirmRedirectingToSignUp:^(UIAlertAction *action) {
                WLLog(@"ERROR - redirection to welcome screen, sign in failed: %@", error);
                [[WLNotificationCenter defaultCenter] clear];
                [[NSUserDefaults standardUserDefaults] clear];
                [storyboard present:YES];
                topView.userInteractionEnabled = YES;
            } tryAgain:^(UIAlertAction *action) {
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
        [WLToast showWithMessage:[error errorMessage]];
    }];
}

- (void)initializeCrashlyticsAndLogging {
    run_release(^{
        [NewRelicAgent enableCrashReporting:YES];
        if ([[Environment currentEnvironment] isProduction]) {
            [NewRelicAgent startWithApplicationToken:@"AAd46869ec0b3558fb5890343d895b3acdd40ebaa8"];
            [[GAI sharedInstance] trackerWithTrackingId:@"UA-60538241-1"];
        } else {
            [NewRelicAgent startWithApplicationToken:@"AA0d33ab51ad09e9b52f556149e4a7292c6d4c480c"];
        }
    });
}

- (void)initializeVersionTool {
    iVersion *version = [iVersion sharedInstance];
    version.appStoreID = Constants.appStoreID;
    version.updateAvailableTitle = @"new_version_is_available".ls;
    version.downloadButtonLabel = @"update".ls;
    version.remindButtonLabel = @"not_now".ls;
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
    
    NSString *storedVersion = [NSUserDefaults standardUserDefaults].appVersion;
    NSString *currentVersion = [NSBundle mainBundle].buildVersion;
    
    if (!storedVersion || [storedVersion compare:@"2.0" options:NSNumericSearch] == NSOrderedAscending) {
        [[NSUserDefaults standardUserDefaults] clear];
    }
    
    if (![storedVersion isEqualToString:currentVersion]) {
        self.versionChanged = YES;
        [NSUserDefaults standardUserDefaults].appVersion = currentVersion;
    }
}

- (void)presentInitialViewController {
    void (^successBlock) (User *user) = ^(User *user) {
        if (user.isSignupCompleted) {
            [[UIStoryboard main] present:YES];
        } else {
            WLLog(@"INITIAL SIGN IN - sign up is not completed, redirecting to profile step");
            UINavigationController *navigation = [[UIStoryboard signUp] instantiateInitialViewController];
            WLSignupFlowViewController *signupFlowViewController = navigation.storyboard [@"WLSignupFlowViewController"];
            signupFlowViewController.registrationNotCompleted = YES;
            navigation.viewControllers = @[signupFlowViewController];
            [UIWindow mainWindow].rootViewController = navigation;
        }
    };
    
    Authorization* authorization = [Authorization currentAuthorization];
    if ([authorization canAuthorize]) {
        if (!self.versionChanged && ![WLAuthorizationRequest requiresSignIn]) {
            User *currentUser = [User currentUser];
            if (currentUser) {
                successBlock(currentUser);
                [currentUser notifyOnAddition];
                return;
            }
        }
        self.window.rootViewController = [[UIViewController alloc] initWithNibName:@"WLLaunchScreenViewController" bundle:nil];
        __weak typeof(self)weakSelf = self;
        [authorization signIn:successBlock failure:^(NSError *error) {
            User *currentUser = [User currentUser];
            if ([error isNetworkError] && currentUser) {
                successBlock(currentUser);
            } else {
                [UIAlertController confirmRedirectingToSignUp:^(UIAlertAction *action) {
                    WLLog(@"INITIAL SIGN IN ERROR - couldn't sign in, so redirecting to welcome screen");
                    [[UIStoryboard signUp] present:YES];
                } tryAgain:^(UIAlertAction *action) {
                    [weakSelf presentInitialViewController];
                }];
            }
        }];
    } else {
        WLLog(@"INITIAL SIGN IN - no data for signing in");
        [[UIStoryboard signUp] present:YES];
    }
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
    if ([url.host isEqualToString:@"extension.com"]) {
        NSArray *components = [url.path pathComponents];
        if (components.count < 2 || ![components[components.count - 2] isEqualToString:@"request"]) {
            return NO;
        }
        ExtensionRequest *request = [ExtensionRequest deserialize:components[components.count - 1]];
        if ([request.action isEqualToString:@"presentEntry"]) {
            [[EventualEntryPresenter sharedPresenter] presentEntry:request.userInfo];
        }
    }
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
        [[UIApplication sharedApplication] openURL:[[NSString stringWithFormat:@"itms-apps://itunes.apple.com/app/id%@",@(Constants.appStoreID)] URL]];
    } else {
        Entry *entry = notification.entry;
        if (entry) {
            NSDictionary *entryReference = [notification.entry serializeReference];
            [[EventualEntryPresenter sharedPresenter] presentEntry:entryReference];
            if ([identifier isEqualToString:@"reply"]) {
                id wrapViewController = [entry viewControllerWithNavigationController:[UINavigationController mainNavigationController]];
                [wrapViewController setShowKeyboard:YES];
            }
        }
    }
}

- (void)registerUserNotificationSettings {
    UIMutableUserNotificationCategory *category = [[UIMutableUserNotificationCategory alloc] init];
    category.identifier = @"chat";
    UIMutableUserNotificationAction *action = [[UIMutableUserNotificationAction alloc] init];
    action.identifier = @"reply";
    action.title = @"reply".ls;
    action.activationMode = UIUserNotificationActivationModeForeground;
    action.authenticationRequired = YES;
    [category setActions:@[action] forContext:UIUserNotificationActionContextDefault];
    UIUserNotificationType types = UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
    UIUserNotificationSettings* settings = [UIUserNotificationSettings settingsForTypes:types categories:[NSSet setWithObject:category]];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
}

// MARK: - WCSessionDelegate

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message replyHandler:(void (^)(NSDictionary<NSString *,id> * _Nonnull))replyHandler {
    static dispatch_once_t onceToken;
    onceToken = 0;
    UIBackgroundTaskIdentifier task = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        dispatch_once(&onceToken, ^{
            if (replyHandler) replyHandler(@{@"response":[[ExtensionResponse failure:@"Background task expired."] serialize]});
        });
    }];
    
    ExtensionRequest *request = [ExtensionRequest deserialize:[message stringForKey:@"request"]];
    [request perform:^ (ExtensionResponse *response) {
        dispatch_once(&onceToken, ^{
            if (replyHandler) replyHandler(@{@"response":[response serialize]});
        });
        [[UIApplication sharedApplication] endBackgroundTask:task];
    }];
}

@end
