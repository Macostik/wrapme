//
//  WLAlertView.h
//  WrapLive
//
//  Created by Yura Granchenko on 04/02/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

@interface WLAlertView : UIView

+ (void)showWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttons completion:(void (^)(NSUInteger index))completion;

+ (void)showWithTitle:(NSString *)title message:(NSString *)message action:(NSString *)action cancel:(NSString *)cancel completion:(void (^)(void))completion;

+ (void)showWithMessage:(NSString *)message;

@end
