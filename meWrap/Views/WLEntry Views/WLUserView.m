//
//  WLUserView.m
//  meWrap
//
//  Created by Ravenpod on 6/4/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLUserView.h"
#import "WLImageView.h"

@implementation WLUserView

- (void)awakeFromNib {
    [super awakeFromNib];
    WLImageView *avatarView = self.avatarView;
    avatarView.layer.borderWidth = WLConstants.pixelSize * 2.0f;
    avatarView.layer.borderColor = [UIColor whiteColor].CGColor;
    avatarView.circled = YES;
    self.entry = [User currentUser];
    [[User notifier] addReceiver:self];
}

- (void)update:(User *)user {
    self.avatarView.url = user.picture.small;
    self.nameLabel.text = user.name;
}

// MARK: - WLEntryNotifyReceiver

- (void)notifier:(EntryNotifier *)notifier didUpdateEntry:(User *)user {
    [self update:user];
}

- (BOOL)notifier:(EntryNotifier *)notifier shouldNotifyOnEntry:(Entry *)entry {
    return self.entry == entry;
}

@end
