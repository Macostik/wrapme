//
//  WLUserView.m
//  WrapLive
//
//  Created by Sergey Maximenko on 6/4/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLUserView.h"
#import "WLImageFetcher.h"
#import "WLUser+Extended.h"
#import "UIView+Shorthand.h"
#import "NSString+Additions.h"
#import "WLEntryNotifier.h"

@interface WLUserView () <WLEntryNotifyReceiver>

@end

@implementation WLUserView

- (void)awakeFromNib {
    [super awakeFromNib];
    WLImageView *avatarView = self.avatarView;
    avatarView.layer.borderWidth = WLConstants.pixelSize * 2.0f;
    avatarView.layer.borderColor = [UIColor whiteColor].CGColor;
    avatarView.circled = YES;
    [avatarView setImageName:@"default-small-avatar" forState:WLImageViewStateEmpty];
    [avatarView setImageName:@"default-small-avatar" forState:WLImageViewStateFailed];
    self.user = [WLUser currentUser];
    [[WLUser notifier] addReceiver:self];
}

- (void)setUser:(WLUser *)user {
    _user = user;
    [self update];
}

- (void)update {
    self.avatarView.url = _user.picture.small;
    self.nameLabel.text = _user.name;
}

// MARK: - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier userUpdated:(WLUser *)user {
    [self update];
}

- (WLUser *)notifierPreferredUser:(WLEntryNotifier *)notifier {
    return self.user;
}

@end
