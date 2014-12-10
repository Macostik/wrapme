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
    entry.lastTouch = [attributes valueForKey:WLLastTouchedAtKey];
    entry.event = evenString;
    entry.wrapName = [attributes valueForKey:WLWrapNameKey];
    entry.time = [attributes valueForKey:WLTimeKey];
    
    return entry;
}

+ (NSURLSessionDataTask *)globalTimelinePostsWithBlock:(void (^)(NSArray *posts, NSError *error))block {
    return [WLExtensionManager postsHandlerBlock:block];
}

- (void)setWrapName:(NSString *)wrapName {
    if (![wrapName isEqualToString:@""]) {
        _wrapName = @"";
        _wrapName = wrapName;
    } else {
        _wrapName = @"empty wrap";
    }
}

- (void)setEvent:(NSString *)event {
    if (![event isEqualToString:@""]) {
        _event = @"";
        _event = event;
    } else  {
        _event= @"";
    }
}

- (void)setTime:(NSDate *)time {
    if (time) {
        _time = time;
    } else {
        _time = [NSDate date];
    }
}

@end

static const NSTimeInterval WLTimeIntervalDay = 86400;
static const NSTimeInterval WLTimeIntervalWeek = 604800;

static NSString *WLTimeIntervalNameMinute = @"minute";
static NSString *WLTimeIntervalNameHour = @"hour";
static NSString *WLTimeIntervalNameDay = @"day";
static NSString *WLTimeIntervalNameWeek = @"week";
static NSString *WLTimeIntervalNameMonth = @"month";
static NSString *WLTimeIntervalNameYear = @"year";
static NSString *WLTimeIntervalLessThanMinute = @"less than 1 minute ago";
static NSString *WLTimeIntervalNameYesterday = @"yesterday";
static NSString *WLTimeIntervalNameToday = @"today";

@implementation NSDate (WLPost)

- (NSString *)timeAgoStringAtAMPM {
    NSTimeInterval interval = ABS([self timeIntervalSinceNow]);
    if (interval >= WLTimeIntervalWeek) {
        return [self stringWithFormat:@"MM/dd/yy 'at' hh:mma"];
    } else {
        NSTimeInterval value = 0;
        NSString* name = nil;
        if ((value = interval / WLTimeIntervalDay) >= 2) {
            return [NSString stringWithFormat:@"%.f %@s ago at %@", value, WLTimeIntervalNameDay, [self stringWithFormat:@"hh:mma"]];
        } else {
            name = ((value = interval / WLTimeIntervalDay) >= 1) ? WLTimeIntervalNameYesterday : WLTimeIntervalNameToday;
            return [NSString stringWithFormat:@"%@ at %@", name, [self stringWithFormat:@"hh:mma"]];
        }
    }
}

@end