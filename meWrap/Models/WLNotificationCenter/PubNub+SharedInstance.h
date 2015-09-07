//
//  PubNub+SharedInstance.h
//  meWrap
//
//  Created by Ravenpod on 7/2/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "PubNub.h"

@interface PubNub (SharedInstance)

+ (instancetype)sharedInstance;

@end
