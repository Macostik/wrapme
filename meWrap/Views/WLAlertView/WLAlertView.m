//
//  WLAlertView.m
//  meWrap
//
//  Created by Yura Granchenko on 04/02/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLAlertView.h"
#import "UIDevice+SystemVersion.h"
#import <objc/runtime.h>
#import "NSObject+AssociatedObjects.h"

@implementation UIAlertController (WLAlertView)

+ (void)showWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttons completion:(WLAlertViewCompletion)completion {
    UIAlertController *alertController = [self alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    for (NSString *button in buttons) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:button style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                     if (completion) {
                                         completion([buttons indexOfObject:button]);
                                     }
                                 }];
        [alertController addAction:action];
    }
    
    UIWindow *mainWindow = [[[UIApplication sharedApplication] windows] firstObject];
    UIViewController *rootViewController = mainWindow.rootViewController.presentedViewController ? : mainWindow.rootViewController;
    [rootViewController presentViewController:alertController animated:YES completion:nil];
}

+ (void)showWithTitle:(NSString *)title message:(NSString *)message cancel:(NSString *)cancel action:(NSString *)action completion:(void (^)(void))completion {
    [self showWithTitle:title message:message buttons:@[cancel, action] completion:^(NSUInteger index) {
        if (index == 1 && completion) {
            completion();
        }
    }];
}

+ (void)showWithTitle:(NSString *)title message:(NSString *)message action:(NSString *)action cancel:(NSString *)cancel completion:(void (^)(void))completion {
    [self showWithTitle:title message:message buttons:@[action, cancel] completion:^(NSUInteger index) {
        if (index == 0 && completion) {
            completion();
        }
    }];
}

+ (void)showWithMessage:(NSString *)message {
    [self showWithTitle:nil message:message buttons:@[WLLS(@"ok")] completion:nil];
}

@end

@implementation UIAlertController (DefinedAlerts)

+ (void)confirmWrapDeleting:(WLWrap*)wrap success:(WLBlock)success failure:(WLFailureBlock)failure {
    NSString *title, *message;
    NSArray *buttons = nil;
    if (wrap.deletable) {
        title = WLLS(@"delete_wrap");
        message = [NSString stringWithFormat:WLLS(@"formatted_delete_wrap_confirmation"), wrap.name];
        buttons = @[WLLS(@"cancel"),WLLS(@"delete")];
    } else {
        if (wrap.isPublic) {
            title = WLLS(@"unfollow_confirmation_title");
            message = WLLS(@"unfollow_confirmation_message");
            buttons = @[WLLS(@"uppercase_no"),WLLS(@"uppercase_yes")];
        } else {
            title = WLLS(@"leave_wrap");
            message = WLLS(@"leave_wrap_confirmation");
            buttons = @[WLLS(@"uppercase_no"),WLLS(@"uppercase_yes")];
        }
    }
    [UIAlertController showWithTitle:title
                       message:message
                       buttons:buttons
                    completion:^(NSUInteger index) {
                        if (index == 1) {
                            if (success) success();
                        } else if (failure) {
                            failure(nil);
                        }
                    }];
}

+ (void)confirmCandyDeleting:(WLCandy *)candy success:(WLBlock)success failure:(WLFailureBlock)failure {
    [UIAlertController showWithTitle:WLLS(@"delete_photo")
                       message:WLLS(@"delete_photo_confirmation")
                       buttons:@[WLLS(@"cancel"),WLLS(@"ok")]
                    completion:^(NSUInteger index) {
                        if (index == 1) {
                            if (success) success();
                        } else if (failure) {
                            failure(nil);
                        }
                    }];
}

+ (void)confirmRedirectingToSignUp:(WLBlock)signUp tryAgain:(WLBlock)tryAgain {
    [UIAlertController showWithTitle:WLLS(@"authorization_error_title") message:WLLS(@"authorization_error_message") buttons:@[WLLS(@"try_again"),WLLS(@"authorization_error_sign_up")] completion:^(NSUInteger index) {
        if (index == 0) {
            if (tryAgain) tryAgain();
        } else {
            if (signUp) signUp();
        }
    }];
}

@end

