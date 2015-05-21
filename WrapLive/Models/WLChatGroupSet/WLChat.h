//
//  WLChatGroupSet.h
//  WrapLive
//
//  Created by Yura Granchenko on 10/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPaginatedSet.h"
#import "WLChatTypingChannel.h"

@class WLChat;

@protocol WLChatDelegate <WLPaginatedSetDelegate>

@optional
- (void)chat:(WLChat*)chat didBeginTyping:(WLUser *)user;

- (void)chat:(WLChat*)chat didEndTyping:(WLUser *)user andSendMessage:(BOOL)sendMessage;

- (void)chatDidChangeMessagesWithName:(WLChat*)chat;

@end

@interface WLChat : WLPaginatedSet

@property (nonatomic, weak) id <WLChatDelegate> delegate;

@property (strong, nonatomic) NSMutableOrderedSet* typingUsers;

@property (strong, nonatomic) NSString* typingNames;

@property (strong, nonatomic) NSMutableOrderedSet* sendMessageUsers;

@property (strong, nonatomic) WLChatTypingChannel* typingChannel;

@property (strong, nonatomic) NSHashTable* messagesWithDay;

@property (strong, nonatomic) NSHashTable* messagesWithName;

@property (strong, nonatomic) NSMutableOrderedSet* unreadMessages;

@property (weak, nonatomic) WLWrap* wrap;

@property (readonly, nonatomic) BOOL showTypingView;

+ (instancetype)chatWithWrap:(WLWrap*)wrap;

- (void)addTypingUser:(WLUser*)user;

- (void)removeTypingUser:(WLUser*)user;

@end

@interface WLPaginatedSet (WLChatGroupSet)

- (NSDate *)date;

@end
