//
//  WLEntryStatusIndicator.m
//  WrapLive
//
//  Created by Yura Granchenko on 22/04/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEntryStatusIndicator.h"

@interface WLEntryStatusIndicator ()

@property (weak, nonatomic) WLContribution *contribution;

@end

@implementation WLEntryStatusIndicator

- (void)updateStatusIndicator:(WLContribution *)contribution {
    self.hidden = !contribution.valid || ![contribution contributor].isCurrentUser;
    if (_contribution != contribution) {
        _contribution = contribution;
        [[[_contribution class] notifier] addReceiver:self];
        if (![(id)[contribution containingEntry] uploaded]) {
            [[[[_contribution containingEntry] class] notifier] addReceiver:self];
        }
    }
    [self setIconNameByCotribution:contribution];
}

- (void)setIconNameByCotribution:(WLContribution *)contribution {
    run_in_main_queue(^{
        self.iconName = iconNameByContribution(contribution);
    });
}

- (void)notifier:(WLEntryNotifier*)notifier wrapUpdated:(WLWrap*)wrap {
    if (self.contribution == wrap)
        [self setIconNameByCotribution:self.contribution];
}

- (void)notifier:(WLEntryNotifier*)notifier candyUpdated:(WLCandy*)candy {
    if (self.contribution == candy || candy == self.contribution.containingEntry)
        [self setIconNameByCotribution:self.contribution];
}

- (void)notifier:(WLEntryNotifier*)notifier commentUpdated:(WLComment*)comment {
    if (self.contribution == comment || comment == self.contribution.containingEntry)
        [self setIconNameByCotribution:self.contribution];
}

- (void)notifier:(WLEntryNotifier *)notifier messageUpdated:(WLMessage *)message {
    if (self.contribution == message || message == self.contribution.containingEntry)
        [self setIconNameByCotribution:self.contribution];
}

@end

