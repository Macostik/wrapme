//
//  WLPreferenceRequest.h
//  WrapLive
//
//  Created by Yura Granchenko on 07/07/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <WrapLiveKit/WrapLiveKit.h>

@interface WLPreferenceRequest : WLAPIRequest

@property (weak, nonatomic) WLWrap *wrap;

+ (instancetype)request:(WLWrap *)wrap;

@end
