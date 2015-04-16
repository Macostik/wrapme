//
//  WLSoundPlayer.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/20/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLSoundPlayer.h"
#import <AudioToolbox/AudioToolbox.h>

static inline NSString *WLSoundFileName(WLSound sound) {
    switch (sound) {
        case WLSound_s01:
            return @"s01";
            break;
        case WLSound_s02:
            return @"s02";
            break;
        case WLSound_s03:
            return @"s03";
            break;
        case WLSound_s04:
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

+ (NSMapTable *)sounds {
    static NSMapTable *sounds = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sounds = [NSMapTable strongToStrongObjectsMapTable];
    });

    return sounds;
}

+ (void)playSound:(WLSound)sound {
    NSString *soundFileName = WLSoundFileName(sound);
    if (soundFileName.nonempty) {
        NSMapTable *sounds = [self sounds];
        SystemSoundID soundID = [[sounds objectForKey:soundFileName] intValue];
        if (soundID == 0) {
            NSString *soundPath = [[NSBundle mainBundle] pathForResource:soundFileName ofType:@"wav"];
            if (soundPath.nonempty) {
                AudioServicesCreateSystemSoundID((__bridge CFURLRef)([NSURL fileURLWithPath:soundPath]), &soundID);
                [sounds setObject:[NSNumber numberWithInteger:soundID] forKey:soundFileName];
            }
        }
        AudioServicesPlaySystemSound(soundID);
    }
}

@end

@implementation WLSoundPlayer (WLNotification)

+ (void)playSoundForNotification:(WLNotification*)notification {
    switch (notification.type) {
        case WLNotificationContributorAdd:
            [self playSound:WLSound_s01];
            break;
        case WLNotificationCommentAdd:
            [self playSound:WLSound_s02];
            break;
        case WLNotificationMessageAdd:
            [self playSound:WLSound_s03];
            break;
        default:
            break;
    }
}

@end