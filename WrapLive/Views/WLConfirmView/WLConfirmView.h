//
//  WLConfirmView.h
//  moji
//
//  Created by Yura Granchenko on 12/15/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLAuthorization;

@interface WLConfirmView : UIView

@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;

+ (void)showInView:(UIView*)view authorization:(WLAuthorization*)authorization success:(WLAuthorizationBlock)succes cancel:(WLBlock)cancel;

- (void)showInView:(UIView*)view authorization:(WLAuthorization*)authorization success:(WLAuthorizationBlock)succes cancel:(WLBlock)cancel;

- (void)confirmationSuccess:(WLObjectBlock)success cancel:(WLBlock)cancel;

@end
