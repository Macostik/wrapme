//
//  WLWrapDay.h
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/27/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEntry.h"

@protocol WLCandy @end

@interface WLWrapDate : WLEntry

@property (strong, nonatomic) NSArray<WLCandy> *candies;

@end
