//
//  WLWhatsUpSet.h
//  meWrap
//
//  Created by Ravenpod on 5/25/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLSet.h"

@class WLWhatsUpSet;
@class WLBroadcaster;

@protocol WLWhatsUpSetBroadcastReceiver <NSObject>

- (void)whatsUpBroadcaster:(WLBroadcaster*)broadcaster updated:(WLWhatsUpSet *)set;

@end

@interface WLWhatsUpSet : WLSet

@property (nonatomic) NSUInteger unreadEntriesCount;

@property (strong, nonatomic) WLBroadcaster *broadcaster;

+ (instancetype)sharedSet;

- (void)update:(Block)success failure:(FailureBlock)failure;

- (void)refreshCount:(void (^)(NSUInteger count))success failure:(FailureBlock)failure;

- (NSUInteger)unreadCandiesCountForWrap:(Wrap *)wrap;

@end
