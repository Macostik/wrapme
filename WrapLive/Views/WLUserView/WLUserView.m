//
//  WLUserView.m
//  WrapLive
//
//  Created by Sergey Maximenko on 6/4/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLUserView.h"
#import "WLImageFetcher.h"
#import "WLUser.h"
#import "UIView+Shorthand.h"

@interface WLUserView ()

@property (weak, nonatomic) IBOutlet WLImageView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@end

@implementation WLUserView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.avatarView.circled = YES;
}

- (void)setUser:(WLUser *)user {
    _user = user;
    [self update];
}

- (void)update {
    self.avatarView.url = _user.picture.small;
    self.nameLabel.text = _user.name;
}

@end
