//
//  WLTimelineEvent.h
//  WrapLive
//
//  Created by Sergey Maximenko on 8/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLTimelineEvent : NSObject

@property (weak, nonatomic) WLUser* user;

@property (strong, nonatomic) NSDate* date;

@property (strong, nonatomic) NSMutableOrderedSet* entries;

@property (strong, nonatomic) NSString *text;

@property (weak, nonatomic) Class entryClass;

@property (weak, nonatomic) WLEntry* containingEntry;

+ (NSMutableOrderedSet*)events:(NSMutableOrderedSet*)entries;

+ (NSMutableOrderedSet*)eventsByAddingEntry:(WLContribution*)entry toEvents:(NSMutableOrderedSet*)events;

+ (NSMutableOrderedSet*)eventsByDeletingEntry:(WLContribution*)entry fromEvents:(NSMutableOrderedSet*)events;

- (BOOL)addEntry:(WLContribution*)entry;

- (BOOL)deleteEntry:(WLContribution*)entry;

@end
