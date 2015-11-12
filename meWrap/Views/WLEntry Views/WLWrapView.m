//
//  WLWrapView.m
//  meWrap
//
//  Created by Ravenpod on 2/6/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWrapView.h"
#import "WLWrapStatusImageView.h"

@implementation WLWrapView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.coverView.circled = YES;
    [[Wrap notifier] addReceiver:self];
}

- (void)update:(Wrap *)wrap {
    self.coverView.url = wrap.picture.small;
    [self.coverView setIsFollowed:wrap.isPublic ? wrap.isContributing : NO];
    [self.coverView setIsOwner:wrap.isPublic ? [wrap.contributor current] : NO];
    self.nameLabel.text = wrap.name;
}

// MARK: - WLEntryNotifyReceiver

- (void)notifier:(EntryNotifier *)notifier didUpdateEntry:(Entry *)entry {
    [self update:(Wrap*)entry];
}

- (BOOL)notifier:(EntryNotifier *)notifier shouldNotifyOnEntry:(Entry *)entry {
    return self.entry == entry;
}

@end
