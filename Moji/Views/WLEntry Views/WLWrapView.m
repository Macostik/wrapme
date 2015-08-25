//
//  WLWrapView.m
//  moji
//
//  Created by Ravenpod on 2/6/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWrapView.h"
#import "UIView+QuartzCoreHelper.h"

@implementation WLWrapView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.coverView.circled = YES;
    [[WLWrap notifier] addReceiver:self];
}

- (void)update:(WLWrap*)wrap {
    self.coverView.url = wrap.picture.small;
    self.nameLabel.text = wrap.name;
}

// MARK: - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier didUpdateEntry:(WLWrap *)wrap {
    [self update:wrap];
}

- (BOOL)notifier:(WLEntryNotifier *)notifier shouldNotifyOnEntry:(WLEntry *)entry {
    return self.entry == entry;
}

@end
