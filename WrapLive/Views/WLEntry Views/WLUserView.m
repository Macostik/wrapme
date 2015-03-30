//
//  WLUserView.m
//  WrapLive
//
//  Created by Sergey Maximenko on 6/4/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLUserView.h"
#import "UIView+Shorthand.h"

@implementation WLUserView

- (void)awakeFromNib {
    [super awakeFromNib];
    WLImageView *avatarView = self.avatarView;
    avatarView.layer.borderWidth = WLConstants.pixelSize * 2.0f;
    avatarView.layer.borderColor = [UIColor whiteColor].CGColor;
    avatarView.circled = YES;
    [avatarView setImageName:@"default-small-avatar" forState:WLImageViewStateEmpty];
    [avatarView setImageName:@"default-small-avatar" forState:WLImageViewStateFailed];
    self.entry = [WLUser currentUser];
    [[WLUser notifier] addReceiver:self];
}

- (void)update:(WLUser*)user {
    self.avatarView.url = user.picture.small;
    self.nameLabel.text = user.name;
}

// MARK: - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier userUpdated:(WLUser *)user {
    [self update:user];
}

- (WLUser *)notifierPreferredUser:(WLEntryNotifier *)notifier {
    return self.entry;
}

@end
