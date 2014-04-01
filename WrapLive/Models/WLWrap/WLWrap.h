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

@protocol WLUser @end

@interface WLWrap : WLWrapEntry

+ (NSMutableArray*)dummyWraps;

@property (strong, nonatomic) NSArray* candies;
@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) NSArray<WLUser>* contributors;
@property (strong, nonatomic) NSDate* contributedAt;
@property (strong, nonatomic) NSString * wrapID;

- (void)addCandy:(WLCandy*)candy;

- (void)contributorNames:(void (^)(NSString* names))completion;

@end
