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

@end

@interface WLChat : WLPaginatedSet

@property (nonatomic, weak) id <WLChatDelegate> delegate;

@property (strong, nonatomic) NSMutableOrderedSet* typingUsers;

@property (strong, nonatomic) NSString* typingNames;

@property (strong, nonatomic) NSMutableOrderedSet* sendMessageUsers;

@property (strong, nonatomic) WLChatTypingChannel* typingChannel;

@property (weak, nonatomic) WLWrap* wrap;

@property (readonly, nonatomic) BOOL showTypingView;

+ (instancetype)chatWithWrap:(WLWrap*)wrap;

- (void)addTypingUser:(WLUser*)user;

- (void)removeTypingUser:(WLUser*)user;

- (void)addMessage:(WLMessage *)message;
- (BOOL)addMessages:(NSOrderedSet *)messages isNewer:(BOOL)newer;
- (void)sort;

@end

@interface WLPaginatedSet (WLChatGroupSet)

- (NSDate *)date;

@end
