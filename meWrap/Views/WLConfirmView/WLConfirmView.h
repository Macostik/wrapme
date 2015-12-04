//
//  WLConfirmView.h
//  meWrap
//
//  Created by Yura Granchenko on 12/15/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WLTextView.h"

@interface WLConfirmView : UIView

@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;

+ (void)showInView:(UIView*)view authorization:(Authorization*)authorization success:(ObjectBlock)succes cancel:(Block)cancel;

- (void)showInView:(UIView*)view authorization:(Authorization*)authorization success:(ObjectBlock)succes cancel:(Block)cancel;

- (void)confirmationSuccess:(ObjectBlock)success cancel:(Block)cancel;

@end

@interface WLEditingConfirmView : WLConfirmView <WLKeyboardBroadcastReceiver>
@property (weak, nonatomic) IBOutlet WLLabel *titleLabel;
@property (weak, nonatomic) IBOutlet WLLabel *bodyLabel;
@property (weak, nonatomic) IBOutlet WLTextView *contentTextView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardPrioritizer;

+ (void)showInView:(UIView *)view withContent:(NSString *)content success:(ObjectBlock)succes cancel:(Block)cancel;

@end
