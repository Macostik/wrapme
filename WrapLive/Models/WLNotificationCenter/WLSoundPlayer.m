//
//  WLSoundPlayer.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/20/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLSoundPlayer.h"
#import <AudioToolbox/AudioToolbox.h>

@implementation WLSoundPlayer

static SystemSoundID soundID;

static BOOL playing = NO;

+ (void)play {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"interfacealertsound3" ofType:@"wav"];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)([NSURL fileURLWithPath: soundPath]), &soundID);
    });
    if (!playing) {
        playing = YES;
        AudioServicesPlaySystemSound (soundID);
        AudioServicesAddSystemSoundCompletion(soundID, NULL, NULL, completionCallback, NULL);
    }
}

static void completionCallback (SystemSoundID  soundID, void *data) {
    playing = NO;
}

@end
