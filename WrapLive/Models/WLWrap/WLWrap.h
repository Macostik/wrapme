//
//  WLWrap.h
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapEntry.h"

static NSString * WLWrapChangesNotification = @"WLWrapChangesNotification";

@class WLCandy;
@class WLUser;

@protocol WLUser @end
@protocol WLCandy @end

@interface WLWrap : WLWrapEntry

@property (strong, nonatomic) NSArray<WLCandy>* candies;
@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) NSArray<WLUser>* contributors;

- (void)addCandy:(WLCandy*)candy;

- (void)contributorNames:(void (^)(NSString* names))completion;

- (WLCandy*)actualConversation;

- (NSArray*)candiesForDate:(NSDate*)date;

+ (NSArray*)candiesForDate:(NSDate*)date inArray:(NSArray*)candies;

@end
