//
//  WLAlertView.m
//  moji
//
//  Created by Yura Granchenko on 04/02/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLAlertView.h"
#import "UIDevice+SystemVersion.h"
#import <objc/runtime.h>
#import "NSObject+AssociatedObjects.h"

@implementation WLAlertView

+ (Class <WLAlertView>)alertViewClass {
    return SystemVersionGreaterThanOrEqualTo8() ? [UIAlertController class] : [UIAlertView class];
}

+ (void)showWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttons completion:(WLAlertViewCompletion)completion {
    [[self alertViewClass] showWithTitle:title message:message buttons:buttons completion:completion];
}

+ (void)showWithMessage:(NSString *)message {
    [[self alertViewClass] showWithMessage:message];
}

+ (void)showWithTitle:(NSString *)title message:(NSString *)message action:(NSString *)action cancel:(NSString *)cancel completion:(void (^)(void))completion {
    [[self alertViewClass] showWithTitle:title message:message action:action cancel:cancel completion:completion];
}

+ (void)showWithTitle:(NSString *)title message:(NSString *)message cancel:(NSString *)cancel action:(NSString *)action completion:(void (^)(void))completion {
    [[self alertViewClass] showWithTitle:title message:message cancel:cancel action:action completion:completion];
}

@end

@implementation WLAlertView (DefinedAlerts)

+ (void)confirmWrapDeleting:(WLWrap*)wrap success:(WLBlock)success failure:(WLFailureBlock)failure {
    NSString *title, *message;
    NSArray *buttons = nil;
    if (wrap.deletable) {
        title = WLLS(@"delete_moji");
        message = [NSString stringWithFormat:WLLS(@"formatted_delete_moji_confirmation"), wrap.name];
        buttons = @[WLLS(@"cancel"),WLLS(@"delete")];
    } else {
        title = WLLS(@"leave_moji");
        message = WLLS(@"leave_moji_confirmation");
        buttons = @[WLLS(@"uppercase_no"),WLLS(@"uppercase_yes")];
    }
    [WLAlertView showWithTitle:title
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
    [WLAlertView showWithTitle:WLLS(@"delete_photo")
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
    [WLAlertView showWithTitle:WLLS(@"authorization_error_title") message:WLLS(@"authorization_error_message") buttons:@[WLLS(@"authorization_error_try_again"),WLLS(@"authorization_error_sign_up")] completion:^(NSUInteger index) {
        if (index == 0) {
            if (tryAgain) tryAgain();
        } else {
            if (signUp) signUp();
        }
    }];
}

@end

@implementation UIAlertView (Blocks)

+ (void)showWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttons completion:(WLAlertViewCompletion)completion {
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    alertView.cancelButtonIndex = -1;
    for (NSString* button in buttons) {
        [alertView addButtonWithTitle:button];
    }
    alertView.completion = completion;
    [alertView show];
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
    [[[self alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:WLLS(@"ok"), nil] show];
}

- (WLAlertViewCompletion)completion {
    return [self associatedObjectForKey:"wl_alertview_completion"];
}

- (void)setCompletion:(WLAlertViewCompletion)completion {
    self.delegate = self;
    [self setAssociatedObject:completion forKey:"wl_alertview_completion"];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    WLAlertViewCompletion completion = self.completion;
    if (completion) {
        completion(buttonIndex);
    }
}

@end

@implementation UIAlertController (Blocks)

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

