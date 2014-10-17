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

@property (strong, nonatomic) WLGroup *group;
@property (strong, nonatomic) WLIdentifierMessage * message;

- (void)addMessage:(WLMessage *)message;

@end
