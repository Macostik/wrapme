//
//  WLChatTypingChannel.h
//  WrapLive
//
//  Created by Sergey Maximenko on 11/7/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLNotificationChannel.h"

@class WLChatTypingChannel;

@protocol WLChatTypingChannelDelegate <NSObject>

- (void)chatTypingChannel:(WLChatTypingChannel*)channel didBeginTyping:(WLUser *)user;

- (void)chatTypingChannel:(WLChatTypingChannel*)channel didEndTyping:(WLUser *)user;

@end

@interface WLChatTypingChannel : WLNotificationChannel

@property (weak, nonatomic) id <WLChatTypingChannelDelegate> delegate;

+ (instancetype)channelWithWrap:(WLWrap *)wrap;

- (void)sendTyping:(BOOL)typing sendMessage:(BOOL)sendMessage;

- (void)beginTyping;

- (void)endTyping:(BOOL)sendMessage;

@end

