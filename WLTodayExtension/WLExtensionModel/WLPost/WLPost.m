//
//  WLPost.m
//  WrapLive
//
//  Created by Yura Granchenko on 11/28/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPost.h"
#import "WLEntryKeys.h"
#import "WLExtensionManager.h"
#import "NSDate+Formatting.h"

@implementation WLPost

+ (id)initWithAttributes:(NSDictionary *)attributes {
    WLPost *entry = [[WLPost alloc] init];
    entry.image = [NSData dataWithContentsOfURL:[NSURL URLWithString:[attributes valueForKey:WLImageKey]]];
    entry.identifier = [attributes valueForKey:WLCandyUIDKey];
    entry.contributor = [attributes valueForKey:WLContributorNameKey];
    entry.comment = [WLComments initWithAttributes:[[attributes valueForKey:WLCommentsKey] firstObject]];
    NSString *evenString = nil;
    if (entry.comment.identifier == nil) {
        evenString = [NSString stringWithFormat:@"%@ posted a new photo", entry.contributor];
    } else {
        evenString = [NSString stringWithFormat:@"%@ commnented \"%@\"", entry.comment.contributorName, entry.comment.comment];
    }
    entry.event = evenString;
    entry.lastTouch = [self convertLastTouchToDate:[attributes valueForKey:WLLastTouchedAtKey]];
    entry.wrapName = [attributes valueForKey:WLWrapNameKey];
    
    return entry;
}

+ (NSURLSessionDataTask *)globalTimelinePostsWithBlock:(void (^)(NSArray *posts, NSError *error))block {
    return [WLExtensionManager postsHandlerBlock:block];
}

+ (NSDate *)convertLastTouchToDate:(NSString *)lastTouchInterval {
    return [NSDate dateWithTimeIntervalSince1970:[lastTouchInterval doubleValue]];
}

@end

@implementation NSDate (WLPost)

- (NSString *)timeAgoStringAtAMPM {
    return [NSString stringWithFormat:@"today at %@", [self stringWithFormat:@"hh:mma"]];
}

- (BOOL)isSameDay:(NSDate *)date {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    if ([calendar component:NSCalendarUnitDay fromDate:self] != [calendar component:NSCalendarUnitDay fromDate:date]) return NO;
    if ([calendar component:NSCalendarUnitMonth fromDate:self] != [calendar component:NSCalendarUnitMonth fromDate:date]) return NO;
    if ([calendar component:NSCalendarUnitYear fromDate:self] != [calendar component:NSCalendarUnitYear fromDate:date]) return NO;
    return YES;
}

@end