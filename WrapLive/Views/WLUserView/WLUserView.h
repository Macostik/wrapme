//
//  WLUserView.h
//  WrapLive
//
//  Created by Sergey Maximenko on 6/4/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLUser;
@class WLImageView;

@interface WLUserView : UIView

@property (weak, nonatomic) IBOutlet WLImageView *avatarView;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (weak, nonatomic) WLUser* user;

- (void)update;

@end
