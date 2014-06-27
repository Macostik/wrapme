//
//  WLWrapEditSession.h
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 6/25/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEditSession.h"
#import "WLTempWrap.h"

@interface WLWrapEditSession : WLEditSession

@property (strong, nonatomic) WLTempWrap *originalEntry;
@property (strong, nonatomic) WLTempWrap *changedEntry;

@end
