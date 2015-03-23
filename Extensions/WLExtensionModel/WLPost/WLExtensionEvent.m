//
//  WLExtensionEvent.m
//  WrapLive
//
//  Created by Yura Granchenko on 11/28/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLExtensionEvent.h"
#import "WLEntryKeys.h"
#import "NSDate+Formatting.h"

@implementation WLExtensionEvent

+ (id)postWithAttributes:(NSDictionary *)attributes {
    WLExtensionEvent *entry = [[WLExtensionEvent alloc] init];
    entry.image = [NSURL URLWithString:[attributes valueForKey:WLImageKey]];
    entry.identifier = [attributes valueForKey:WLCandyUIDKey];
    entry.contributor = [attributes valueForKey:WLContributorNameKey];
    entry.comment = [WLExtensionComment commentWithAttributes:[[attributes valueForKey:WLCommentsKey] firstObject]];
    if (entry.comment) {
        entry.type = WLExtensionEventTypeComment;
        entry.event = [NSString stringWithFormat:@"%@ commented \"%@\"", entry.comment.contributorName, entry.comment.comment];
    } else {
        entry.type = WLExtensionEventTypeCandy;
        entry.event = [NSString stringWithFormat:@"%@ posted a new photo", entry.contributor];
    }
    entry.lastTouch = [self convertLastTouchToDate:[attributes valueForKey:WLLastTouchedAtKey]];
    entry.wrapName = [attributes valueForKey:WLWrapNameKey];
    return entry;
}

+ (NSURLSessionDataTask *)posts:(WLArrayBlock)success failure:(WLFailureBlock)failure {
    return nil;
}

+ (NSDate *)convertLastTouchToDate:(NSString *)lastTouchInterval {
    return [NSDate dateWithTimeIntervalSince1970:[lastTouchInterval doubleValue]];
}

@end