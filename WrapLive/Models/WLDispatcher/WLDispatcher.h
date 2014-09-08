//
//  WLDispatcher.h
//  WrapLive
//
//  Created by Sergey Maximenko on 9/8/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLBlockDispatch.h"

@interface WLDispatcher : NSObject

@property (strong, nonatomic) NSMapTable *receivers;

- (void)addReceiver:(id)receiver dispatch:(WLDispatch*)dispatch;

- (void)addReceiver:(id)receiver block:(WLBlock)block;

- (void)addReceiver:(id)receiver selector:(SEL)selector;

- (void)send;

@end
