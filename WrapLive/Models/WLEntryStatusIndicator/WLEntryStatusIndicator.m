//
//  WLEntryStatusIndicator.m
//  WrapLive
//
//  Created by Yura Granchenko on 22/04/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEntryStatusIndicator.h"

@interface WLEntryStatusIndicator () <WLEntryNotifyReceiver>

@property (weak, nonatomic) WLContribution *contribution;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *widthConstraint;

@end

@implementation WLEntryStatusIndicator

- (void)updateStatusIndicator:(WLContribution *)contribution {
    self.hidden = contribution.invalid || !contribution.contributedByCurrentUser;
    if (self.widthConstraint) {
        [UIView performWithoutAnimation:^{
            self.widthConstraint.constant = self.hidden ? 0 : WLIndicatorWidth;
            [self layoutIfNeeded];
        }];
    }
    if (_contribution != contribution) {
        _contribution = contribution;
        [[[contribution class] notifier] addReceiver:self];
        WLContribution *containingEntry = (id)[contribution containingEntry];
        if (![containingEntry uploaded]) {
            [[[containingEntry class] notifier] addReceiver:self];
        }
    }
    [self setIconNameByCotribution:contribution];
}

- (void)setIconNameByCotribution:(WLContribution *)contribution {
    run_in_main_queue(^{
        self.iconName = iconNameByContribution(contribution);
    });
}

- (void)notifier:(WLEntryNotifier*)notifier entryUpdated:(WLEntry *)entry {
    [self setIconNameByCotribution:self.contribution];
}

- (BOOL)notifier:(WLEntryNotifier *)notifier shouldNotifyOnEntry:(WLEntry *)entry {
    WLContribution *contribution = self.contribution;
    return contribution == entry || (contribution.containingEntry && entry == contribution.containingEntry);
}

@end

