//
//  WLComments.m
//  WrapLive
//
//  Created by Yura Granchenko on 12/4/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLComments.h"
#import "WLEntryKeys.h"

@implementation WLComments

+ (instancetype)initWithAttributes:(NSDictionary *)attributes {
    WLComments *comment = [[WLComments alloc] init];
    comment.identifier = [[attributes valueForKey:WLCandyUIDKey] firstObject];
    comment.contributorName = [[attributes valueForKey:WLContributorNameKey] firstObject];
    comment.comment = [[attributes valueForKey:WLContentKey] firstObject];
    
    return comment;
}

@end
