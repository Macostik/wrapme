//
//  WLWhatsUpEvent.m
//  meWrap
//
//  Created by Ravenpod on 5/25/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWhatsUpEvent.h"

@implementation WLWhatsUpEvent

+ (instancetype)event:(WLEvent)evnt contribution:(id)contribution {
    WLWhatsUpEvent *event = [[WLWhatsUpEvent alloc] init];
    event.event = evnt;
    event.contribution = contribution;
    return event;
}

- (NSDate *)date {
    if (self.event == WLEventUpdate) {
        return [self.contribution editedAt];
    }
    return [self.contribution createdAt];
}

@end
