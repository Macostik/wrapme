//
//  WLComments.m
//  WrapLive
//
//  Created by Yura Granchenko on 12/4/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLExtensionComment.h"
#import "WLEntryKeys.h"

@implementation WLExtensionComment

+ (instancetype)commentWithAttributes:(NSDictionary *)attributes {
    if (attributes) {
        WLExtensionComment *comment = [[WLExtensionComment alloc] init];
        comment.identifier = [attributes valueForKey:WLCandyUIDKey];
        comment.contributorName = [attributes valueForKey:WLContributorNameKey];
        comment.comment = [attributes valueForKey:WLContentKey];
        return comment;
    }
    return nil;
}

@end
