//
//  WLSoundPlayer.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/20/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLSoundPlayer.h"
#import <AudioToolbox/AudioToolbox.h>

typedef NS_ENUM(NSUInteger, WLSoundType) {
    WLNotSound,
    WLNewContiributor,
    WLNewComment,
    WLNewMessage,
    WLSendMessage
};

static inline NSString * WLPlaySoundType(WLSoundType type) {
    switch (type) {
            
        case WLNotSound:
            return nil;
            break;
        case WLNewContiributor:
            return @"s01";
            break;
        case WLNewComment:
            return @"s02";
            break;
        case WLNewMessage:
            return @"s03";
            break;
        case WLSendMessage:
            return @"s04";
            break;
            
            default:
            return nil;
            break;
    }
}

@interface WLSoundPlayer()

@property (strong, nonatomic) NSMapTable *sounds;

@end

@implementation WLSoundPlayer

static BOOL playing = NO;

+ (NSMapTable *)sounds {
    static NSMapTable *sounds = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sounds = [NSMapTable strongToStrongObjectsMapTable];
    });

    return sounds;
}

+ (void)playSoundByName:(NSString *)nameSound {
    if (nameSound.nonempty) {
        NSMapTable *sounds = [self sounds];
        SystemSoundID soundID = [[sounds objectForKey:nameSound] intValue];
        if (soundID == 0) {
            NSString *soundPath = [[NSBundle mainBundle] pathForResource:nameSound ofType:@"wav"];
            if (soundPath.nonempty) {
                AudioServicesCreateSystemSoundID((__bridge CFURLRef)([NSURL fileURLWithPath:soundPath]), &soundID);
                [sounds setObject:[NSNumber numberWithInteger:soundID] forKey:nameSound];
            }
        }
        
        if (!playing) {
            playing = YES;
            AudioServicesPlaySystemSound (soundID);
            AudioServicesAddSystemSoundCompletion(soundID, NULL, NULL, completionCallback, NULL);
        }
    }
}

static void completionCallback (SystemSoundID  soundID, void *data) {
    playing = NO;
}

@end

@implementation WLEntry (WLSoundPlayer)

- (void)playSoundBySendEvent {
    NSString *soundName = WLPlaySoundType(WLSendMessage);
    [WLSoundPlayer playSoundByName:soundName];
}

@end

@implementation  WLNotification (WLSoundPlayer)

- (void)playNotificationSound {
    NSString *soundName = nil;
    switch (self.type) {
        case WLNotificationContributorAdd:
            soundName = WLPlaySoundType(WLNewContiributor);
            break;
        case WLNotificationCommentAdd:
            soundName = WLPlaySoundType(WLNewComment);
            break;
        case WLNotificationMessageAdd:
            soundName = WLPlaySoundType(WLNewMessage);
            break;
            
        default:
            soundName = WLPlaySoundType(WLNotSound);
            break;
    }
    [WLSoundPlayer playSoundByName:soundName];
}

@end