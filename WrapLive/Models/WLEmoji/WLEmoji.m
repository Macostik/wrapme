//
//  WLEmoji.m
//  moji
//
//  Created by Oleg Vishnivetskiy on 6/5/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEmoji.h"
#import "NSPropertyListSerialization+Shorthand.h"

static NSInteger WLMaxRecentEmojiCount = 21;
static NSArray *_recentEmoji = nil;

@implementation WLEmoji

+ (NSArray *)recentEmoji {
    NSArray * recentEmoji = WLSession.recentEmojis;
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
    NSMutableArray * recentEmoji = [NSMutableArray arrayWithArray:WLSession.recentEmojis];
    if (![recentEmoji containsObject:emoji]) {
        [recentEmoji addObject:emoji];
        if (recentEmoji.count > WLMaxRecentEmojiCount) {
            [recentEmoji removeObjectAtIndex:0];
        }
    } else {
        [recentEmoji removeObject:emoji];
        [recentEmoji addObject:emoji];
    }
    WLSession.recentEmojis = recentEmoji;
}

@end