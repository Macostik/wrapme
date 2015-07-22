//
//  WLUserRequest.h
//  WrapLive
//
//  Created by Yura Granchenko on 22/07/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <WrapLiveKit/WrapLiveKit.h>

@interface WLUserRequest : WLAPIRequest

@property (weak, nonatomic) WLUser *user;

+ (instancetype)request:(WLUser *)user;

@end
