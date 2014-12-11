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
        _wrapName = @"";
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

@implementation NSDate (WLPost)

- (NSString *)timeAgoStringAtAMPM {
    return [NSString stringWithFormat:@"today at %@", [self stringWithFormat:@"hh:mma"]];
}

- (BOOL)isToday {
    return (ABS([self timeIntervalSinceNow])/WLTimeIntervalDay <= 1.0f);
}

@end