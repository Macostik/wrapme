//
//  WLSoundPlayer.h
//  WrapLive
//
//  Created by Sergey Maximenko on 8/20/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLNotification;

typedef NS_ENUM(NSUInteger, WLSound) {
    WLSound_s01,
    WLSound_s02,
    WLSound_s03,
    WLSound_s04,
    WLSound_s06
};

@interface WLSoundPlayer : NSObject

+ (void)playSound:(WLSound)sound;

@end

@interface WLSoundPlayer (WLNotification)

+ (void)playSoundForNotification:(WLNotification*)notification;

@end
