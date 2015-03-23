//
//  InterfaceController.m
//  WrapLive-Development WatchKit Extension
//
//  Created by Sergey Maximenko on 12/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLWKEventsController.h"
#import "WLWKCommentEventRow.h"
#import "NSURL+WLRemoteEntryHandler.h"
#import "WLExtensionEvent.h"
#import "NSDate+Formatting.h"
#import <WrapLiveKit/WLRecentContributionsRequest.h>
#import <WrapLiveKit/WLEntry+Extended.h>

@interface WLWKEventsController()

@property (strong, nonatomic) IBOutlet WKInterfaceTable *table;

@property (strong, nonatomic) NSOrderedSet* entries;

@end


@implementation WLWKEventsController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    
}

- (void)setEntries:(NSOrderedSet *)entries {
    _entries = entries;
    
    NSMutableArray *rowTypes = [NSMutableArray array];
    for (WLEntry *entry in entries) {
        if ([entry isKindOfClass:[WLCandy class]]) {
            [rowTypes addObject:WLExtensionEventTypeCandy];
        } else {
            [rowTypes addObject:WLExtensionEventTypeComment];
        }
    }
    
    [self.table setRowTypes:rowTypes];
    
    for (WLEntry *entry in entries) {
        NSUInteger index = [entries indexOfObject:entry];
        WLWKEntryRow* row = [self.table rowControllerAtIndex:index];
        [row setEntry:entry];
    }
}

//- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
//    WLExtensionEvent *event = self.events[rowIndex];
//    [WKInterfaceController openParentApplication:@{@"event":[event archive]} reply:^(NSDictionary *replyInfo, NSError *error) {
//        
//    }];
//}

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
    __weak typeof(self)weakSelf = self;
    [[WLRecentContributionsRequest request] send:^(id object) {
        weakSelf.entries = object;
    } failure:^(NSError *error) {
        
    }];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end



