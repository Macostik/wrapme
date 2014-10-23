//
//  WLChatGroupSet.h
//  WrapLive
//
//  Created by Yura Granchenko on 10/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLGroupedSet.h"

@class WLIdentifierMessage;

@interface WLChatGroupSet : WLPaginatedSet

@property (strong, nonatomic) WLIdentifierMessage * message;

- (void)addMessage:(WLMessage *)message;
- (BOOL)addMessages:(NSOrderedSet *)messages pullDownToRefresh:(BOOL)flag;
- (void)sort;

@end

@interface WLPaginatedSet (WLChatGroupSet)

- (NSDate *)date;
- (WLUser *)user;

@end

@implementation WLPaginatedSet (WLChatGroupSet)

- (NSDate *)date {
    return [self.entries.firstObject createdAt];
}

- (WLUser *)user {
    return [self.entries.firstObject contributor];
}
@end
