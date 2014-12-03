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

@end