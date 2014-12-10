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
    comment.identifier = [attributes valueForKey:WLCandyUIDKey];
    comment.contributorName = [attributes valueForKey:WLContributorNameKey];
    comment.comment = [attributes valueForKey:WLContentKey];
    
    return comment;
}

@end
