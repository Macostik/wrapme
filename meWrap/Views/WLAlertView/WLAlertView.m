//
//  WLAlertView.m
//  meWrap
//
//  Created by Yura Granchenko on 04/02/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLAlertView.h"

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
    [self showWithTitle:nil message:message buttons:@[@"ok".ls] completion:nil];
}

@end

@implementation UIAlertController (DefinedAlerts)

+ (void)confirmWrapDeleting:(Wrap *)wrap success:(WLBlock)success failure:(WLFailureBlock)failure {
    NSString *title, *message;
    NSArray *buttons = nil;
    if (wrap.deletable) {
        title = @"delete_wrap".ls;
        message = [NSString stringWithFormat:@"formatted_delete_wrap_confirmation".ls, wrap.name];
        buttons = @[@"cancel".ls,@"delete".ls];
    } else {
        if (wrap.isPublic) {
            title = @"unfollow_confirmation_title".ls;
            message = @"unfollow_confirmation_message".ls;
            buttons = @[@"uppercase_no".ls,@"uppercase_yes".ls];
        } else {
            title = @"leave_wrap".ls;
            message = @"leave_wrap_confirmation".ls;
            buttons = @[@"uppercase_no".ls,@"uppercase_yes".ls];
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

+ (void)confirmCandyDeleting:(Candy *)candy success:(WLBlock)success failure:(WLFailureBlock)failure {
    [UIAlertController showWithTitle:@"delete_photo".ls
                             message:[(candy.isVideo ? @"delete_video_confirmation" : @"delete_photo_confirmation") ls]
                             buttons:@[@"cancel".ls,@"ok".ls]
                          completion:^(NSUInteger index) {
                              if (index == 1) {
                                  if (success) success();
                              } else if (failure) {
                                  failure(nil);
                              }
                          }];
}

+ (void)confirmRedirectingToSignUp:(WLBlock)signUp tryAgain:(WLBlock)tryAgain {
    [UIAlertController showWithTitle:@"authorization_error_title".ls message:@"authorization_error_message".ls buttons:@[@"try_again".ls,@"authorization_error_sign_up".ls] completion:^(NSUInteger index) {
        if (index == 0) {
            if (tryAgain) tryAgain();
        } else {
            if (signUp) signUp();
        }
    }];
}

@end

