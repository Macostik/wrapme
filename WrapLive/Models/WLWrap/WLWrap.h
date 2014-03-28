//
//  WLWrap.h
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEntry.h"

@class WLCandy;

@interface WLWrap : WLEntry

+ (NSMutableArray*)dummyWraps;

@property (strong, nonatomic) NSArray* candies;
@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) NSString* cover;
@property (strong, nonatomic) NSArray* contributors;

- (void)addCandy:(WLCandy*)candy;

@end
