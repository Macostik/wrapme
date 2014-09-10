//
//  WLUploadWrapRequest.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAPIRequest.h"

@interface WLUploadWrapRequest : WLAPIRequest

@property (strong, nonatomic) WLWrap* wrap;

@property (nonatomic) BOOL creation;

+ (instancetype)request:(WLWrap*)wrap;

@end
