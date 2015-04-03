//
//  WLAlertView.m
//  WrapLive
//
//  Created by Yura Granchenko on 04/02/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLAlertView.h"
#import "UIDevice+SystemVersion.h"
#ifndef WRAPLIVE_EXTENSION_TERGET
#import "UIAlertController+Blocks.h"
#import "UIAlertView+Blocks.h"
#endif

@implementation WLAlertView

+ (void)showWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttons completion:(void (^)(NSUInteger index))completion {
#ifndef WRAPLIVE_EXTENSION_TERGET
    Class alertClass = SystemVersionGreaterThanOrEqualTo8() ? [UIAlertController class] : [UIAlertView class];
    [alertClass showWithTitle:title message:message buttons:buttons completion:completion];
#else
    if (completion) completion(0);
#endif
}

@end

