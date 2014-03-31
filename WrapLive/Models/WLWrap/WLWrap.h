//
//  WLWrap.h
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEntry.h"

@class WLCandy;
@class WLUser;
@class WLPicture;

@protocol WLUser @end

@interface WLWrap : WLEntry

+ (NSMutableArray*)dummyWraps;

@property (strong, nonatomic) NSArray* candies;
@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) WLPicture* cover;
@property (strong, nonatomic) NSArray<WLUser>* contributors;
@property (strong, nonatomic) NSDate* contributedAt;
@property (strong, nonatomic) NSString * wrapID;

- (void)addCandy:(WLCandy*)candy;

@end
