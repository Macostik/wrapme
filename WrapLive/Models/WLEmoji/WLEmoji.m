//
//  WLEmoji.m
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 6/5/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEmoji.h"
#import "NSPropertyListSerialization+Shorthand.h"

static NSInteger WLMaxRecentEmojiCount = 21;
static NSArray *_recentEmoji = nil;

@implementation WLEmoji

+ (NSArray *)recentEmoji {
    NSArray * recentEmoji = [[NSUserDefaults standardUserDefaults] arrayForKey:WLEmojiTypeRecent];
    if (recentEmoji.nonempty) {
        return [[recentEmoji reverseObjectEnumerator] allObjects];
    } else {
        return recentEmoji;
    }
}

+ (NSArray *)emojiByType:(NSString *)type {
    return [NSArray resourcePropertyListNamed:type];
}

+ (void)saveAsRecent:(NSString *)emoji {
    NSMutableArray * recentEmoji = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:WLEmojiTypeRecent]];
    if (![recentEmoji containsObject:emoji]) {
        [recentEmoji addObject:emoji];
        if (recentEmoji.count > WLMaxRecentEmojiCount) {
            [recentEmoji removeObjectAtIndex:0];
        }
    } else {
        [recentEmoji removeObject:emoji];
        [recentEmoji addObject:emoji];
    }
    [[NSUserDefaults standardUserDefaults] setObject:recentEmoji forKey:WLEmojiTypeRecent];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end