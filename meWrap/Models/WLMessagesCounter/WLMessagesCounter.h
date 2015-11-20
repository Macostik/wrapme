//
//  WLMessagesCounter.h
//  meWrap
//
//  Created by Ravenpod on 7/15/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLMessagesCounter, Wrap;

@protocol WLMessagesCounterReceiver <NSObject>

- (void)counterDidChange:(WLMessagesCounter*)counter;

@end

@interface WLMessagesCounter : WLBroadcaster

+ (instancetype)instance;

- (NSUInteger)countForWrap:(Wrap *)wrap;

- (void)update:(WLBlock)completionHandler;

@end
