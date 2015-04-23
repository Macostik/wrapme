//
//  InterfaceController.m
//  WrapLive-Development WatchKit Extension
//
//  Created by Sergey Maximenko on 12/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLWKContributionsController.h"
#import "WLWKCommentEventRow.h"

typedef NS_ENUM(NSUInteger, WLWKContributionsState) {
    WLWKContributionsStateDefault,
    WLWKContributionsStateLoading,
    WLWKContributionsStateEmpty,
    WLWKContributionsStateError
};

@interface WLWKContributionsController() <WLEntryNotifyReceiver>

@property (strong, nonatomic) IBOutlet WKInterfaceTable *table;

@property (strong, nonatomic) NSOrderedSet* entries;
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *errorGroup;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *errorLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *placeholderGroup;

@property (nonatomic) WLWKContributionsState state;

@end


@implementation WLWKContributionsController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    self.entries = [WLContribution recentContributions];
    [[WLComment notifier] addReceiver:self];
    [[WLCandy notifier] addReceiver:self];
    
    [[WLNotificationCenter defaultCenter] configure];
}

- (void)setState:(WLWKContributionsState)state {
    _state = state;
    switch (state) {
        case WLWKContributionsStateLoading:
            [self.table setHidden:YES];
            [self.errorGroup setHidden:YES];
            [self.placeholderGroup setHidden:YES];
            break;
        case WLWKContributionsStateEmpty:
            [self.table setHidden:YES];
            [self.errorGroup setHidden:YES];
            [self.placeholderGroup setHidden:NO];
            break;
        case WLWKContributionsStateError:
            [self.table setHidden:YES];
            [self.errorGroup setHidden:NO];
            [self.placeholderGroup setHidden:YES];
            break;
        default:
            [self.table setHidden:NO];
            [self.errorGroup setHidden:YES];
            [self.placeholderGroup setHidden:YES];
            break;
    }
}

- (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)remoteNotification {
    WLEntryNotification *notification = [WLEntryNotification notificationWithData:remoteNotification];
    WLEntry *entry = notification.targetEntry;
    if (entry) {
        __weak typeof(self)weakSelf = self;
        [entry recursivelyFetchIfNeeded:^ {
            if ([entry isKindOfClass:[WLComment class]]) {
                [weakSelf pushControllerWithName:@"candy" context:entry.containingEntry];
            } else if ([entry isKindOfClass:[WLCandy class]]) {
                [weakSelf pushControllerWithName:@"candy" context:entry];
            } else if ([identifier isEqualToString:@"reply"] && [entry isKindOfClass:[WLMessage class]]) {
                [weakSelf pushControllerWithName:@"chatReply" context:entry.containingEntry];
            }
        } failure:nil];
    }
}

- (void)setEntries:(NSOrderedSet *)entries {
    _entries = entries;
    
    NSMutableArray *rowTypes = [NSMutableArray array];
    for (WLEntry *entry in entries) {
        if ([entry isKindOfClass:[WLCandy class]]) {
            [rowTypes addObject:@"candy"];
        } else {
            [rowTypes addObject:@"comment"];
        }
    }
    
    if (rowTypes.nonempty) {
        self.state = WLWKContributionsStateDefault;
    } else {
        self.state = WLWKContributionsStateEmpty;
    }
    
    [self.table setRowTypes:rowTypes];
    
    for (WLEntry *entry in entries) {
        NSUInteger index = [entries indexOfObject:entry];
        WLWKEntryRow* row = [self.table rowControllerAtIndex:index];
        [row setEntry:entry];
    }
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
    if (self.entries.count == 0) {
        __weak typeof(self)weakSelf = self;
        [WKInterfaceController openParentApplication:@{@"action":@"authorization"} reply:^(NSDictionary *replyInfo, NSError *error) {
            if (error) {
                [weakSelf showError:error];
            } else {
                BOOL success = [replyInfo boolForKey:@"success"];
                NSString *message = [replyInfo stringForKey:@"message"];
                if (!success && message) {
                    [weakSelf showError:WLError(message)];
                } else {
                    [weakSelf updateContributions];
                }
            }
        }];
    }
}

- (void)showError:(NSError*)error {
    [self.errorLabel setText:error.localizedDescription];
    self.state = WLWKContributionsStateError;
    [self.table setRowTypes:@[]];
}

- (id)contextForSegueWithIdentifier:(NSString *)segueIdentifier inTable:(WKInterfaceTable *)table rowIndex:(NSInteger)rowIndex {
    WLEntry *entry = self.entries[rowIndex];
    if ([entry isKindOfClass:[WLComment class]]) {
        return [(id)entry candy];
    }
    return entry;
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    [self updateContributions];
}

- (void)updateContributions {
    __weak typeof(self)weakSelf = self;
    
    if (!self.entries.nonempty) {
        self.state = WLWKContributionsStateLoading;
    }
    if ([WLAuthorizationRequest authorized]) {
        [[WLRecentContributionsRequest request] send:^(id object) {
            weakSelf.entries = [WLContribution recentContributions];
        } failure:^(NSError *error) {
            [weakSelf showError:error];
        }];
    } else if ([[WLAuthorization currentAuthorization] canAuthorize]) {
        [[WLAuthorization currentAuthorization] signIn:^(WLUser *user) {
            [weakSelf updateContributions];
        } failure:^(NSError *error) {
            [weakSelf showError:error];
        }];
    } else {
        [weakSelf showError:WLError(@"No data for authorization. Please, check wrapLive app on you iPhone.")];
    }
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

// MARK: - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier candyAdded:(WLCandy *)candy {
    self.entries = [WLContribution recentContributions];
}

- (void)notifier:(WLEntryNotifier *)notifier candyDeleted:(WLCandy *)candy {
    self.entries = [WLContribution recentContributions];
}

- (void)notifier:(WLEntryNotifier *)notifier commentAdded:(WLComment *)comment {
    self.entries = [WLContribution recentContributions];
}

- (void)notifier:(WLEntryNotifier *)notifier commentDeleted:(WLComment *)comment {
    self.entries = [WLContribution recentContributions];
}

@end



