//
//  UIAlertView+Blocks.h
//  WrapLive
//
//  Created by Sergey Maximenko on 05.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^WLAlertViewCompletion)(NSUInteger index);

@interface UIAlertView (Blocks)

+ (void)showWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttons completion:(WLAlertViewCompletion)completion;

+ (void)showWithTitle:(NSString *)title message:(NSString *)message cancel:(NSString *)cancel action:(NSString *)action completion:(void (^)(void))completion;

+ (void)showWithTitle:(NSString *)title message:(NSString *)message action:(NSString *)action cancel:(NSString *)cancel completion:(void (^)(void))completion;

@end
