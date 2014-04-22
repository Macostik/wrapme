//
//  WLWrap.h
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapEntry.h"

@class WLCandy;
@class WLUser;
@class WLWrapDate;

@protocol WLUser @end
@protocol WLWrapDate @end

@interface WLWrap : WLWrapEntry

@property (strong, nonatomic) NSArray<WLWrapDate>* dates;
@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) NSArray<WLUser>* contributors;

- (void)addCandy:(WLCandy*)candy;

- (void)removeCandy:(WLCandy*)candy;

- (void)edit:(BOOL (^)(WLWrap* wrap))editing;

- (NSArray*)latestCandies:(NSInteger)count;

- (NSArray*)getAllImages;

- (void)contributorNames:(void (^)(NSString* names))completion;

- (WLWrapDate*)actualDate;

- (void)broadcastChange;

- (void)broadcastCreation;

- (BOOL)isEqualToWrap:(WLWrap*)wrap;

@end
