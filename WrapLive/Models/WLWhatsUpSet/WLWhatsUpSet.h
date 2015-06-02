//
//  WLWhatsUpSet.h
//  wrapLive
//
//  Created by Sergey Maximenko on 5/25/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <WrapLiveKit/WrapLiveKit.h>

@interface WLWhatsUpSet : WLPaginatedSet

@property (nonatomic) NSUInteger unreadEntriesCount;

+ (instancetype)sharedSet;

- (void)update;

- (NSUInteger)unreadCandiesCountForWrap:(WLWrap*)wrap;

@end
