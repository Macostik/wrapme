//
//  WLSoundPlayer.m
//  meWrap
//
//  Created by Ravenpod on 8/20/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLSoundPlayer.h"
#import <AudioToolbox/AudioToolbox.h>

@interface WLSoundPlayer()

@end

@implementation WLSoundPlayer

static Block _completionBlock;

static WLSound currentSound;

+ (void)initialize {
    currentSound = WLSound_Off;
}

+ (NSMapTable *)sounds {
    static NSMapTable *sounds = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sounds = [NSMapTable strongToStrongObjectsMapTable];
    });

    return sounds;
}

void WLSoundPlayerCompletion (SystemSoundID ssID, void *clientData) {
    if (_completionBlock) {
        _completionBlock();
        _completionBlock = nil;
    }
}

+ (void)playSound:(WLSound)sound {
    if (currentSound == sound || [UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        return;
    }
    if (currentSound == WLSound_Off) {
        currentSound = sound;
    }
    [[RunQueue soundPlayerQueue] run:^(Block finish) {
        currentSound = sound;
        [self playSound:sound completion:^{
            currentSound = WLSound_Off;
            finish();
        }];
    }];
}

+ (void)playSound:(WLSound)sound completion:(Block)completion {
    NSString *soundFileName = WLSoundFileName(sound);
    if (soundFileName.nonempty) {
        NSMapTable *sounds = [self sounds];
        SystemSoundID soundID = [[sounds objectForKey:soundFileName] intValue];
        if (soundID == 0) {
            NSString *soundPath = [[NSBundle mainBundle] pathForResource:soundFileName ofType:nil];
            if (soundPath.nonempty) {
                AudioServicesCreateSystemSoundID((__bridge CFURLRef)([NSURL fileURLWithPath:soundPath]), &soundID);
                AudioServicesAddSystemSoundCompletion(soundID, NULL, NULL, WLSoundPlayerCompletion, NULL);
                [sounds setObject:[NSNumber numberWithInteger:soundID] forKey:soundFileName];
            }
        }
        _completionBlock = completion;
        AudioServicesPlaySystemSound(soundID);
    } else {
        if (completion) completion();
        _completionBlock = nil;
    }
}

@end

@implementation WLSoundPlayer (WLNotification)

+ (void)playSoundForNotification:(Notification*)notification {
    if (notification.playSound) {
        switch (notification.type) {
            case NotificationTypeContributorAdd:
                if ([[User currentUser].uid isEqualToString:notification.data[@"user_uid"]]) {
                     [self playSound:WLSound_s01];
                }
                break;
            case NotificationTypeCommentAdd:
                [self playSound:WLSound_s02];
                break;
            case NotificationTypeMessageAdd:
                [self playSound:WLSound_s03];
                break;
            default:
                break;
        }
    }
}

@end