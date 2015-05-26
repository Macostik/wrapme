//
//  WLWhatsUpEvent.m
//  wrapLive
//
//  Created by Sergey Maximenko on 5/25/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWhatsUpEvent.h"

@implementation WLWhatsUpEvent

- (NSDate *)date {
    if (self.event == WLEventUpdate) {
        return [self.contribution editedAt];
    }
    return [self.contribution createdAt];
}

@end
