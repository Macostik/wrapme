//
//  InterfaceController.m
//  WrapLive-Development WatchKit Extension
//
//  Created by Sergey Maximenko on 12/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLWKContributionsController.h"
#import "WLWKCommentEventRow.h"
#import "WLWKErrorRow.h"

@interface WLWKContributionsController()

@property (strong, nonatomic) IBOutlet WKInterfaceTable *table;

@property (strong, nonatomic) NSOrderedSet* entries;

@end


@implementation WLWKContributionsController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    self.entries = [WLContribution recentContributions];
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
    self.entries = nil;
    [self.table setRowTypes:@[@"error"]];
    WLWKErrorRow* row = [self.table rowControllerAtIndex:0];
    [row setError:error];
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

@end



