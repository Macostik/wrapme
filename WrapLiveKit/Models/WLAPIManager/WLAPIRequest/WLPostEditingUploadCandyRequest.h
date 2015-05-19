//
//  WLPostEditingUploadCandyRequest.h
//  WrapLive
//
//  Created by Yura Granchenko on 19/05/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <WrapLiveKit/WrapLiveKit.h>

@interface WLPostEditingUploadCandyRequest : WLUploadAPIRequest

@property (weak, nonatomic) WLCandy* candy;

+ (instancetype)request:(WLCandy*)candy;


@end
