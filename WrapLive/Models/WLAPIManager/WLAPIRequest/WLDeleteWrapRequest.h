//
//  WLDeleteWrapRequest.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAPIRequest.h"

@interface WLDeleteWrapRequest : WLAPIRequest

@property (weak, nonatomic) WLWrap* wrap;

+ (instancetype)request:(WLWrap*)wrap;

@end
