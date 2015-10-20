//
//  WLEmoji.m
//  meWrap
//
//  Created by Oleg Vishnivetskiy on 6/5/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEmoji.h"

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
    return [NSArray plist:type];
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