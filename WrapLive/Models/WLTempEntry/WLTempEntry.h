//
//  WLTempEntry.h
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 6/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLEntry;

@interface WLTempEntry : NSObject

- (instancetype)initWithEntry:(WLEntry *)entry;

@end
