//
//  WLAlertView.m
//  WrapLive
//
//  Created by Yura Granchenko on 04/02/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLAlertView.h"
#import "UIDevice+SystemVersion.h"

@implementation WLAlertView

#ifndef WRAPLIVE_EXTENSION_TERGET

+ (void)showWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttons completion:(WLAlertViewCompletion)completion {
    Class alertClass = SystemVersionGreaterThanOrEqualTo8() ? [UIAlertController class] : [UIAlertView class];
    [alertClass showWithTitle:title message:message buttons:buttons completion:completion];
}

#else

+ (void)showWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttons completion:(void (^)(NSUInteger index))completion {
    if (completion) completion(0);
}

#endif

@end

