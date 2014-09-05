//
//  WLNotification.h
//  WrapLive
//
//  Created by Yura Granchenko on 9/2/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEntry.h"

@class WLEntry;

@interface WLNotification : WLEntry

@property (nonatomic, retain) NSNumber *type;
@property (nonatomic, retain) WLEntry *entry;

@end
