//
//  WLResendInviteRequest.h
//  WrapLive
//
//  Created by Sergey Maximenko on 3/3/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLAPIRequest.h"

@class WLWrap;
@class WLUser;

@interface WLResendInviteRequest : WLAPIRequest

@property (weak, nonatomic) WLWrap *wrap;

@property (weak, nonatomic) WLUser* user;

+ (instancetype)request:(WLWrap *)wrap;

@end
