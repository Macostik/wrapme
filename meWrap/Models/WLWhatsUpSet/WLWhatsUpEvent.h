//
//  WLWhatsUpEvent.h
//  meWrap
//
//  Created by Ravenpod on 5/25/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLCommonEnums.h"

@interface WLWhatsUpEvent : NSObject

@property (nonatomic) WLEvent event;

@property (strong, nonatomic) id contribution;

@property (readonly, nonatomic) NSDate *date;

+ (instancetype)event:(WLEvent)evnt contribution:(id)contribution;

@end
