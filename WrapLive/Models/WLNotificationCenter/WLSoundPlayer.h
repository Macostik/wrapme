//
//  WLSoundPlayer.h
//  WrapLive
//
//  Created by Sergey Maximenko on 8/20/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLNotification.h"

@interface WLSoundPlayer : NSObject

+ (void)playSoundByName:(NSString *)nameSound;

@end

@interface WLEntry (WLSoundPlayer)

- (void)playSoundBySendEvent;

@end

@interface WLNotification (WLSoundPlayer)

- (void)playSound;

@end
