//
//  InterfaceController.m
//  moji-Development WatchKit Extension
//
//  Created by Ravenpod on 12/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLWKContributionsController.h"
#import "WLWKCommentEventRow.h"
#import "WKInterfaceController+SimplifiedTextInput.h"
#import "WLWKParentApplicationContext.h"

typedef NS_ENUM(NSUInteger, WLWKContributionsState) {
    WLWKContributionsStateDefault,
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

- (void)setState:(WLWKContributionsState)state {
    _state = state;
    switch (state) {
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
    __weak typeof(self)weakSelf = self;
    WLEntry *entry = [WLEntry entryFromDictionaryRepresentation:remoteNotification[@"entry"]];
    if ([entry isKindOfClass:[WLComment class]]) {
        [weakSelf pushControllerWithName:@"candy" context:entry.container];
    } else if ([entry isKindOfClass:[WLCandy class]]) {
        [weakSelf pushControllerWithName:@"candy" context:entry];
    } else if ([identifier isEqualToString:@"reply"] && [entry isKindOfClass:[WLMessage class]]) {
        run_after(0.2f,^{
            [weakSelf presentTextInputControllerWithSuggestionsFromFileNamed:@"WLWKChatReplyPresets" completion:^(NSString *result) {
                WLWrap *wrap = [(WLMessage*)entry wrap];
                [WLWKParentApplicationContext postMessage:result wrap:wrap.identifier success:^(NSDictionary *replyInfo) {
                    [weakSelf pushControllerWithName:@"alert" context:[NSString stringWithFormat:@"Message \"%@\" sent!", result]];
                } failure:^(NSError *error) {
                    [weakSelf pushControllerWithName:@"alert" context:error];
                }];
            }];
        });
    }
}

- (void)setEntries:(NSOrderedSet *)entries {
    _entries = entries;
    
    NSMutableArray *rowTypes = [NSMutableArray array];
    for (WLEntry *entry in entries) {
        [rowTypes addObject:[[entry class] name]];
    }
    
    if (rowTypes.nonempty) {
        self.state = WLWKContributionsStateDefault;
    } else {
        self.state = WLWKContributionsStateEmpty;
    }
    
    [self.table setRowTypes:rowTypes];
    
    for (WLEntry *entry in entries) {
        [[WLEntryManager manager].context refreshObject:entry mergeChanges:NO];
        NSUInteger index = [entries indexOfObject:entry];
        WLWKEntryRow* row = [self.table rowControllerAtIndex:index];
        [row setEntry:entry];
    }
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
    if (self.entries.count == 0) {
        __weak typeof(self)weakSelf = self;
        [WLWKParentApplicationContext requestAuthorization:^(NSDictionary *replyInfo) {
            [weakSelf updateContributions];
        } failure:^(NSError *error) {
            [weakSelf showError:error];
        }];
    } else {
        WLEntry *entry = self.entries[rowIndex];
        if (entry.valid) {
            if ([entry isKindOfClass:[WLComment class]]) {
                [self pushControllerWithName:@"candy" context:[(id)entry candy]];
            } else if ([entry isKindOfClass:[WLCandy class]]) {
                [self pushControllerWithName:@"candy" context:entry];
            }
        }
    }
}

- (void)showError:(NSError*)error {
    [self.errorLabel setText:error.localizedDescription];
    self.state = WLWKContributionsStateError;
    [self.table setRowTypes:@[]];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    [self updateContributions];
}

- (void)updateContributions {
    if ([WLSession.authorization canAuthorize]) {
        self.entries = [WLContribution recentContributions:10];
    } else {
        [self showError:WLError(@"No data for authorization. Please, check MOJI app on you iPhone.")];
    }
}

@end



