//
//  WLUploadCandyRequest.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLUploadAPIRequest.h"

@interface WLUploadCandyRequest : WLUploadAPIRequest

@property (strong, nonatomic) WLCandy* candy;

+ (instancetype)request:(WLCandy*)candy;

@end
