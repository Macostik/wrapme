//
//  WLWhatsUpSet.h
//  wrapLive
//
//  Created by Sergey Maximenko on 5/25/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <WrapLiveKit/WrapLiveKit.h>

@class WLWhatsUpSet;

@protocol WLWhatsUpDelegate <NSObject>

- (void)whatsUpSet:(WLWhatsUpSet *)set figureOutUnreadEntryCounter:(NSUInteger)counter;

@end

@interface WLWhatsUpSet : WLPaginatedSet

@property (nonatomic) NSUInteger unreadEntriesCount;

@property (weak, nonatomic) id <WLWhatsUpDelegate> counterDelegate;

+ (instancetype)sharedSet;

- (void)update;

- (NSUInteger)unreadCandiesCountForWrap:(WLWrap*)wrap;

@end
