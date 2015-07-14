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
    WLSound_Off,
    WLSound_s01,
    WLSound_s02,
    WLSound_s03,
    WLSound_s04
};

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

@interface WLSoundPlayer : NSObject

+ (void)playSound:(WLSound)sound;

@end

@interface WLSoundPlayer (WLNotification)

+ (void)playSoundForNotification:(WLNotification*)notification;

@end
