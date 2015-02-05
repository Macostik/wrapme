//
//  UIAlertController+Blocks.m
//  WrapLive
//
//  Created by Yura Granchenko on 04/02/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "UIAlertController+Blocks.h"

@implementation UIAlertController (Blocks)

+ (void)showWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttons completion:(WLAlertViewCompletion)completion {
    UIAlertController *alertController = [self alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    for (NSString *button in buttons) {
        UIAlertAction *action = [UIAlertAction
                                 actionWithTitle:button
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction *action) {
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

@end
