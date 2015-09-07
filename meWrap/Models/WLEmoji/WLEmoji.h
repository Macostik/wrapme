//
//  WLEmoji.h
//  meWrap
//
//  Created by Oleg Vishnivetskiy on 6/5/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString* WLEmojiTypeSmiles = @"smiles";
static NSString* WLEmojiTypeFlowers = @"flowers";
static NSString* WLEmojiTypeRings = @"rings";
static NSString* WLEmojiTypeCars = @"cars";
static NSString* WLEmojiTypeNumbers = @"numbers";

@interface WLEmoji : NSObject

@property (strong, nonatomic) NSArray *recentEmoji;

+ (NSArray *)recentEmoji;
+ (NSArray *)emojiByType:(NSString *)type;
+ (void)saveAsRecent:(NSString*)emoji;


@end
