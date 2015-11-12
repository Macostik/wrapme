//
//  WLChatGroupSet.h
//  meWrap
//
//  Created by Yura Granchenko on 10/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPaginatedSet.h"

@class WLChat;

@protocol WLChatDelegate <WLPaginatedSetDelegate>

@optional
- (void)chat:(WLChat*)chat didBeginTyping:(User *)user;

- (void)chat:(WLChat*)chat didEndTyping:(User *)user;

- (void)chatDidChangeMessagesWithName:(WLChat*)chat;

@end

@interface WLChat : WLPaginatedSet

@property (nonatomic, weak) id <WLChatDelegate> delegate;

@property (strong, nonatomic) NSMutableOrderedSet* typingUsers;

@property (strong, nonatomic) NSString* typingNames;

@property (strong, nonatomic) NSHashTable* messagesWithDay;

@property (strong, nonatomic) NSHashTable* messagesWithName;

@property (strong, nonatomic) NSMutableOrderedSet* unreadMessages;

@property (strong, nonatomic) NSMutableOrderedSet* readMessages;

@property (strong, nonatomic) NSMutableOrderedSet* groupMessages;

@property (weak, nonatomic) Wrap *wrap;

+ (instancetype)chatWithWrap:(Wrap *)wrap;

- (void)sendTyping:(BOOL)typing;

- (void)beginTyping;

- (void)endTyping;

- (void)markAsRead;

@end
