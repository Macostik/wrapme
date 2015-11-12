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

+ (void)showInView:(UIView*)view authorization:(Authorization*)authorization success:(WLObjectBlock)succes cancel:(WLBlock)cancel;

- (void)showInView:(UIView*)view authorization:(Authorization*)authorization success:(WLObjectBlock)succes cancel:(WLBlock)cancel;

- (void)confirmationSuccess:(WLObjectBlock)success cancel:(WLBlock)cancel;

@end
