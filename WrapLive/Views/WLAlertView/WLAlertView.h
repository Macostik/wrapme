//
//  WLAlertView.h
//  WrapLive
//
//  Created by Yura Granchenko on 04/02/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "UIAlertController+Blocks.h"
#import "UIAlertView+Blocks.h"

@interface WLAlertView : UIView

+ (void)showWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttons completion:(WLAlertViewCompletion)completion;

@end
