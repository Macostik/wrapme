//
//  WLEntryStatusIndicator.m
//  WrapLive
//
//  Created by Yura Granchenko on 22/04/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEntryStatusIndicator.h"

@interface WLEntryStatusIndicator ()

@property (weak, nonatomic) WLEntry *entry;

@end

@implementation WLEntryStatusIndicator

- (void)updateStatusIndicator:(WLContribution *)contribution {
    self.hidden = !contribution.valid;
    if (_entry != contribution) {
        _entry = contribution;
        [[[_entry class] notifier] addReceiver:self];
    }
    run_in_main_queue(^{
         self.iconName = iconNameByStatus(contribution.status);
    });
}

- (void)notifier:(WLEntryNotifier*)notifier wrapUpdated:(WLWrap*)wrap {
    [self updateStatusIndicator:wrap];
}

- (void)notifier:(WLEntryNotifier*)notifier candyUpdated:(WLCandy*)candy {
    [self updateStatusIndicator:candy];
}

- (void)notifier:(WLEntryNotifier*)notifier commentUpdated:(WLComment*)comment {
    [self updateStatusIndicator:comment];
}

- (void)notifier:(WLEntryNotifier *)notifier messageUpdated:(WLMessage *)message {
    [self updateStatusIndicator:message];
}

- (WLEntry *)notifierPreferredWrap:(WLEntryNotifier *)notifier {
    return self.entry;
}

- (WLEntry *)notifierPreferredCandy:(WLEntryNotifier *)notifier {
    return self.entry;
}

- (WLEntry *)notifierPreferredComment:(WLEntryNotifier *)notifier {
    return self.entry;
}

- (WLEntry *)notifierPreferredMessage:(WLEntryNotifier *)notifier {
    return self.entry;
}

@end
