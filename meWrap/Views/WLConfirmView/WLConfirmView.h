//
//  WLConfirmView.h
//  meWrap
//
//  Created by Yura Granchenko on 12/15/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLConfirmView : UIView

@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;

+ (void)showInView:(UIView*)view authorization:(Authorization*)authorization success:(ObjectBlock)succes cancel:(Block)cancel;

- (void)showInView:(UIView*)view authorization:(Authorization*)authorization success:(ObjectBlock)succes cancel:(Block)cancel;

- (void)confirmationSuccess:(ObjectBlock)success cancel:(Block)cancel;

@end

@interface WLEditingConfirmView : WLConfirmView <KeyboardNotifying>
@property (weak, nonatomic) IBOutlet Label *titleLabel;
@property (weak, nonatomic) IBOutlet Label *bodyLabel;
@property (weak, nonatomic) IBOutlet TextView *contentTextView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardPrioritizer;

+ (void)showInView:(UIView *)view withContent:(NSString *)content success:(ObjectBlock)succes cancel:(Block)cancel;

@end
