//
//  WLChatGroupSet.h
//  WrapLive
//
//  Created by Yura Granchenko on 10/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPaginatedSet.h"

@interface WLChat : WLPaginatedSet

@property (strong, nonatomic) NSMutableOrderedSet* typingUsers;

- (void)addTypingUser:(WLUser*)user;

- (void)removeTypingUser:(WLUser*)user;

- (void)addMessage:(WLMessage *)message;
- (BOOL)addMessages:(NSOrderedSet *)messages isNewer:(BOOL)newer;
- (void)sort;

@end

@interface WLPaginatedSet (WLChatGroupSet)

- (NSDate *)date;

@end
