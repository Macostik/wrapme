//
//  WLLeaveWrapRequest.h
//  WrapLive
//
//  Created by Yura Granchenko on 9/18/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAPIRequest.h"

@interface WLLeaveWrapRequest : WLAPIRequest

+ (instancetype)request:(WLWrap *)wrap;

@property(strong, nonatomic) WLWrap *wrap;

@end
