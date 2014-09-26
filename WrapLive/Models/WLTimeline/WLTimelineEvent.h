//
//  WLTimelineEvent.h
//  WrapLive
//
//  Created by Sergey Maximenko on 8/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLUser;
@class WLContribution;

@interface WLTimelineEvent : NSObject

@property (strong, nonatomic) WLUser* user;

@property (strong, nonatomic) NSDate* date;

@property (strong, nonatomic) NSMutableOrderedSet* entries;

@property (strong, nonatomic) NSString *text;

@property (weak, nonatomic) Class entryClass;

+ (NSMutableOrderedSet*)events:(NSMutableOrderedSet*)entries;

- (BOOL)addEntry:(WLContribution*)entry;

@end
