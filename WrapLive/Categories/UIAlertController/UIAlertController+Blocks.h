//
//  UIAlertController+Blocks.h
//  WrapLive
//
//  Created by Yura Granchenko on 04/02/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^WLAlertViewCompletion)(NSUInteger index);

@interface UIAlertController (Blocks)

+ (void)showWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttons completion:(WLAlertViewCompletion)completion;

@end
