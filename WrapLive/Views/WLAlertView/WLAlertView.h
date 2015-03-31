//
//  WLAlertView.h
//  WrapLive
//
//  Created by Yura Granchenko on 04/02/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "UIAlertController+Blocks.h"

#ifndef WRAPLIVE_EXTENSION_TERGET
#import "UIAlertView+Blocks.h"
#endif

@interface WLAlertView : UIView

#ifndef WRAPLIVE_EXTENSION_TERGET

+ (void)showWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttons completion:(WLAlertViewCompletion)completion;

#else

+ (void)showWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttons completion:(void (^)(NSUInteger index))completion;

#endif

@end
