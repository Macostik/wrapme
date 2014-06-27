//
//  WLProfileEditSession.h
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 6/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEditSession.h"
#import "WLTempProfile.h"

@interface WLProfileEditSession : WLEditSession

@property (strong, nonatomic) WLTempProfile *originalEntry;
@property (strong, nonatomic) WLTempProfile *changedEntry;

@end
