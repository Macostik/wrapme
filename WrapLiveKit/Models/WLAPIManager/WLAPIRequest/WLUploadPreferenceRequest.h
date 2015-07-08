//
//  WLUploadPreferenceRequest.h
//  WrapLive
//
//  Created by Yura Granchenko on 07/07/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <WrapLiveKit/WrapLiveKit.h>

@interface WLUploadPreferenceRequest : WLAPIRequest

@property (weak, nonatomic) WLWrap *wrap;
@property (assign, nonatomic) BOOL candyNotify;
@property (assign, nonatomic) BOOL chatNotify;

+ (instancetype)request:(WLWrap *)wrap;

@end
