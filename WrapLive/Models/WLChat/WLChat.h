//
//  WLChatGroupSet.h
//  WrapLive
//
//  Created by Yura Granchenko on 10/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPaginatedSet.h"

@class WLChat;

@protocol WLChatDelegate <WLPaginatedSetDelegate>

@optional
- (void)chat:(WLChat*)chat didBeginTyping:(WLUser *)user;

- (void)chat:(WLChat*)chat didEndTyping:(WLUser *)user;

- (void)chatDidChangeMessagesWithName:(WLChat*)chat;

@end

@interface WLChat : WLPaginatedSet

@property (nonatomic, weak) id <WLChatDelegate> delegate;

@property (strong, nonatomic) NSMutableOrderedSet* typingUsers;

@property (strong, nonatomic) NSString* typingNames;

@property (strong, nonatomic) NSHashTable* messagesWithDay;

@property (strong, nonatomic) NSHashTable* messagesWithName;

@property (strong, nonatomic) NSMutableOrderedSet* unreadMessages;

@property (weak, nonatomic) WLWrap* wrap;

@property (readonly, nonatomic) BOOL showTypingView;

+ (instancetype)chatWithWrap:(WLWrap*)wrap;

- (void)sendTyping:(BOOL)typing sendMessage:(BOOL)sendMessage;

- (void)beginTyping;

- (void)endTyping:(BOOL)sendMessage;

- (BOOL)showUnreadMessagesViewForMessgae:(WLMessage*)message;

- (void)refreshUnreadMessages:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure;

- (NSUInteger)unreadMessagesCount;

@end
