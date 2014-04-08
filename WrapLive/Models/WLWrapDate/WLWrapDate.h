//
//  WLWrapDay.h
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/27/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEntry.h"

@class WLCandy;

@protocol WLCandy @end

@interface WLWrapDate : WLEntry

@property (strong, nonatomic) NSArray<WLCandy> *candies;

- (void)addCandy:(WLCandy *)candy;

@end
