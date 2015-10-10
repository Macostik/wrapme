//
//  WLDevice.h
//  meWrap
//
//  Created by Ravenpod on 11/10/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEntry.h"

@class WLUser;

@interface WLDevice : WLEntry

@property (nonatomic, retain) NSDate * invitedAt;
@property (nonatomic, retain) NSString * invitedBy;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSString * name;
@property (nonatomic) BOOL activated;
@property (nonatomic, retain) WLUser *owner;

@end
