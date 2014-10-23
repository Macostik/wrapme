//
//  WLChatGroupSet.h
//  WrapLive
//
//  Created by Yura Granchenko on 10/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPaginatedSet.h"

@interface WLChatGroupSet : WLPaginatedSet

- (void)addMessage:(WLMessage *)message;
- (BOOL)addMessages:(NSOrderedSet *)messages pullDownToRefresh:(BOOL)flag;
- (void)sort;

@end

@interface WLPaginatedSet (WLChatGroupSet)

- (NSDate *)date;

@end
