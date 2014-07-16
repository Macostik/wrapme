//
//  WLWrapRequest.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAPIRequest.h"

@interface WLWrapRequest : WLAPIRequest

@property (strong, nonatomic) WLWrap* wrap;

@property (nonatomic) NSInteger page;

+ (instancetype)request:(WLWrap*)wrap;

+ (instancetype)request:(WLWrap*)wrap page:(NSInteger)page;

@end
