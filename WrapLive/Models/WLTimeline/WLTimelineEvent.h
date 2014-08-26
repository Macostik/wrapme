//
//  WLTimelineEvent.h
//  WrapLive
//
//  Created by Sergey Maximenko on 8/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLUser;

@interface WLTimelineEvent : NSObject

@property (strong, nonatomic) WLUser* user;

@property (strong, nonatomic) NSDate* date;

@property (strong, nonatomic) NSMutableOrderedSet* images;

@property (strong, nonatomic) NSString *text;

@end
