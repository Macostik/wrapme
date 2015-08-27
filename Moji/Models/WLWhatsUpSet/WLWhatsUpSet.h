//
//  WLWhatsUpSet.h
//  moji
//
//  Created by Ravenpod on 5/25/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <MojiKit/MojiKit.h>

@class WLWhatsUpSet;
@class WLBroadcaster;

@protocol WLWhatsUpSetBroadcastReceiver <NSObject>

- (void)whatsUpBroadcaster:(WLBroadcaster*)broadcaster updated:(WLWhatsUpSet *)set;

@end

@interface WLWhatsUpSet : WLSet

@property (nonatomic) NSUInteger unreadEntriesCount;

@property (strong, nonatomic) WLBroadcaster *broadcaster;

+ (instancetype)sharedSet;

- (void)update:(WLBlock)success failure:(WLFailureBlock)failure;

- (void)refreshCount:(void (^)(NSUInteger count))success failure:(WLFailureBlock)failure;

- (NSUInteger)unreadCandiesCountForWrap:(WLWrap*)wrap;

@end
