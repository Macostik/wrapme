//
//  WLPost.m
//  WrapLive
//
//  Created by Yura Granchenko on 11/28/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPost.h"
#import "WLEntryKeys.h"

static const NSTimeInterval WLTimeIntervalMinute = 60;
static const NSTimeInterval WLTimeIntervalHour = 3600;
static const NSTimeInterval WLTimeIntervalDay = 86400;
static const NSTimeInterval WLTimeIntervalWeek = 604800;

static NSString *WLTimeIntervalNameMinute = @"minute";
static NSString *WLTimeIntervalNameHour = @"hour";
static NSString *WLTimeIntervalNameDay = @"day";
static NSString *WLTimeIntervalNameWeek = @"week";
static NSString *WLTimeIntervalNameMonth = @"month";
static NSString *WLTimeIntervalNameYear = @"year";
static NSString *WLTimeIntervalLessThanMinute = @"less than 1 minute ago";
static NSInteger WLDaySeconds = 24*60*60;

@implementation WLPost
@synthesize image = _image;

+ (id)initWithAttributes:(NSDictionary *)attributes {
   WLPost *entry = [[WLPost alloc] init];
    entry.image = [NSData dataWithContentsOfURL:[NSURL URLWithString:[attributes valueForKey:WLImageKey]]];
    entry.event = [attributes valueForKey:WLEventKey];
    entry.wrapName = [attributes valueForKey:WLWrapKey];
    entry.time = [attributes valueForKey:WLTimeKey];
    return entry;
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
        _event= @"--";
    }
}

- (void)setTime:(NSDate *)time {
    if (time) {
        _time = time;
    } else {
        _time = [NSDate date];
    }
}

- (NSString *)timeAgoString:(NSDate *)date {
    NSTimeInterval interval = ABS([date timeIntervalSinceNow]);
    NSTimeInterval value = 0;
    NSString* name = nil;
    if ((value = interval / WLTimeIntervalDay) >= 1) {
        name = WLTimeIntervalNameDay;
    } else if ((value = interval / WLTimeIntervalHour) >= 1) {
        name = WLTimeIntervalNameHour;
    } else if ((value = interval / WLTimeIntervalMinute) >= 1) {
        name = WLTimeIntervalNameMinute;
    } else {
        return WLTimeIntervalLessThanMinute;
    }
    value = floor(value);
    return [NSString stringWithFormat:@"%.f %@%@ ago", value, name, (value == 1 ? @"":@"s")];
}

@end
