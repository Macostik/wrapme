//
//  WLAppDelegate.m
//  meWrap
//
//  Created by Ravenpod on 19.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAppDelegate.h"
#import "WLNotificationCenter.h"
#import "WLHomeViewController.h"
#import "iVersion.h"
#import "WLSignupFlowViewController.h"
#import "GAI.h"
#import <NewRelicAgent/NewRelic.h>
#import "WLToast.h"
#import "WLWrapViewController.h"
#import "CocoaLumberjack.h"
#import <AWSCore/AWSCore.h>
#import "MMWormhole.h"

@import WatchConnectivity;

@interface WLAppDelegate () <iVersionDelegate, WCSessionDelegate, NetworkNotifying>

@property (nonatomic) BOOL versionChanged;

@property (strong, nonatomic) MMWormhole *wormhole;

@end

@implementation WLAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Logger log:[NSString stringWithFormat:@"meWrap - API environment initialized: %@", [Environment currentEnvironment]]];
    
    [self registerUserNotificationSettings];
    
    [self initializeCrashlyticsAndLogging];
    
    [self initializeAPIManager];
    
    [[WLNotificationCenter defaultCenter] configure];
    
    [self createWindow];
    
    [self presentInitialViewController];
    
    [self initializeVersionTool];
    
	[[Network sharedNetwork] addReceiver:self];
	
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
    
    self.wormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:@"group.com.ravenpod.wraplive" optionalDirectory:@"wormhole"];
    [self.wormhole listenForMessageWithIdentifier:@"recentUpdatesRequest" listener:^(id  _Nullable messageObject) {
        [self.wormhole passMessageObject:[Contribution recentUpdates:6] identifier:@"recentUpdatesResponse"];
    }];
    
	return YES;
}

- (void)initializeAPIManager {
    [APIRequest setUnauthorizedErrorBlock:^ (APIRequest *request, NSError *error) {
        [Logger log:[NSString stringWithFormat:@"UNAUTHORIZED_ERROR: %@", error]];
        UIStoryboard *storyboard = [UIStoryboard signUp];
        UIWindow *window = [UIWindow mainWindow];
        if (window.rootViewController.storyboard != storyboard) {
            UIView *topView = (window.rootViewController.presentedViewController ? : window.rootViewController).view;
            topView.userInteractionEnabled = YES;
            [UIAlertController confirmRedirectingToSignUp:^(UIAlertAction *action) {
                [Logger log:[NSString stringWithFormat:@"ERROR - redirection to welcome screen, sign in failed: %@", error]];
                [[WLNotificationCenter defaultCenter] clear];
                [[NSUserDefaults standardUserDefaults] clear];
                [storyboard present:YES];
                topView.userInteractionEnabled = YES;
            } tryAgain:^(UIAlertAction *action) {
                topView.userInteractionEnabled = NO;
                ObjectBlock successBlock = request.successBlock;
                FailureBlock failureBlock = request.failureBlock;
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
#ifndef DEBUG
    [NewRelicAgent enableCrashReporting:YES];
    if ([[Environment currentEnvironment] isProduction]) {
        [NewRelicAgent startWithApplicationToken:@"AAd46869ec0b3558fb5890343d895b3acdd40ebaa8"];
        [[GAI sharedInstance] trackerWithTrackingId:@"UA-60538241-1"];
    } else {
        [NewRelicAgent startWithApplicationToken:@"AA0d33ab51ad09e9b52f556149e4a7292c6d4c480c"];
    }
#endif
}

- (void)initializeVersionTool {
    iVersion *version = [iVersion sharedInstance];
    version.appStoreID = Constants.appStoreID;
    version.updateAvailableTitle = @"new_version_is_available".ls;
    version.downloadButtonLabel = @"update".ls;
    version.remindButtonLabel = @"not_now".ls;
    version.updatePriority = iVersionUpdatePriorityMedium;
}

- (void)createWindow {
    [[UIWindow mainWindow] makeKeyAndVisible];
    
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
            UINavigationController *navigation = [[UIStoryboard main] instantiateInitialViewController];
            UIViewController *viewController = user.firstTimeUse ? navigation.storyboard[@"FirstTimeBeginViewController"] :
                                                     navigation.storyboard [@"WLHomeViewController"];
            navigation.viewControllers = @[viewController];
            [UIWindow mainWindow].rootViewController = navigation;
        } else {
            [Logger log:[NSString stringWithFormat:@"INITIAL SIGN IN - sign up is not completed, redirecting to profile step"]];
            UINavigationController *navigation = [[UIStoryboard signUp] instantiateInitialViewController];
            WLSignupFlowViewController *signupFlowViewController = navigation.storyboard [@"WLSignupFlowViewController"];
            signupFlowViewController.registrationNotCompleted = YES;
            navigation.viewControllers = @[signupFlowViewController];
            [UIWindow mainWindow].rootViewController = navigation;
        }
    };

    Authorization* authorization = [Authorization currentAuthorization];
    if ([authorization canAuthorize]) {
        if (!self.versionChanged && ![Authorization requiresSignIn]) {
            User *currentUser = [User currentUser];
            if (currentUser) {
                successBlock(currentUser);
                [currentUser notifyOnAddition];
                return;
            }
        }
        [UIWindow mainWindow].rootViewController = [UIStoryboard introduction][@"launchScreen"];
        __weak typeof(self)weakSelf = self;
        [[authorization signIn] send:successBlock failure:^(NSError *error) {
            User *currentUser = [User currentUser];
            if ([error isNetworkError] && currentUser) {
                successBlock(currentUser);
            } else {
                [UIAlertController confirmRedirectingToSignUp:^(UIAlertAction *action) {
                    [Logger log:[NSString stringWithFormat:@"INITIAL SIGN IN ERROR - couldn't sign in, so redirecting to welcome screen"]];
                    [[UIStoryboard signUp] present:YES];
                } tryAgain:^(UIAlertAction *action) {
                    [weakSelf presentInitialViewController];
                }];
            }
        }];
    } else {
        [Logger log:[NSString stringWithFormat:@"INITIAL SIGN IN - no data for signing in"]];
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
    [[WLNotificationCenter defaultCenter] handleRemoteNotification:userInfo success:^(Notification *notification) {
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
    
    [[WLNotificationCenter defaultCenter] handleRemoteNotification:userInfo success:^(Notification *notification) {
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
        [request perform:^(ExtensionReply *reply) {
        } failure:^(ExtensionError *error) {
            [[error generateError] show];
        }];
        return YES;
    } else {
        return NO;
    }
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    __block void (^completion)(UIBackgroundFetchResult) = completionHandler;
    
    if (![Authorization active]) {
        if (completion) {
            completion(UIBackgroundFetchResultFailed);
            completion = nil;
        }
        return;
    }
    [[Uploader wrapUploader] start];
    [[Dispatch mainQueue] after:20 block:^{
        if (completion) {
            completion(UIBackgroundFetchResultNewData);
            completion = nil;
        }
    }];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[Uploader wrapUploader] start];
}

- (void)presentNotification:(Notification *)notification {
    [self presentNotification:notification handleActionWithIdentifier:nil];
}

- (void)presentNotification:(Notification *)notification handleActionWithIdentifier:(NSString *)identifier {
    
    NotificationType type = notification.type;
    if (type == NotificationTypeUpdateAvailable) {
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
            if (replyHandler) replyHandler(@{@"error":[[[ExtensionError alloc] initWithMessage:@"Background task expired."] toDictionary]});
        });
    }];
    
    ExtensionRequest *request = [ExtensionRequest fromDictionary:[message dictionaryForKey:@"request"]];
    [request perform:^(ExtensionReply *reply) {
        dispatch_once(&onceToken, ^{
            if (replyHandler) replyHandler(@{@"success":[reply toDictionary]});
        });
        [[UIApplication sharedApplication] endBackgroundTask:task];
    } failure:^(ExtensionError *error) {
        dispatch_once(&onceToken, ^{
            if (replyHandler) replyHandler(@{@"error":[error toDictionary]});
        });
        [[UIApplication sharedApplication] endBackgroundTask:task];
    }];
}

// MARK: - NetworkNotifying

- (void)networkDidChangeReachability:(Network *)network {
    if (network.reachable) {
        if ([Authorization active]) {
            [[Uploader wrapUploader] start];
        } else {
            [[[Authorization currentAuthorization] signIn] send];
        }
    }
}

@end
