//
//  WLCandiesRequest.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPaginatedRequest.h"

@interface WLCandiesRequest : WLPaginatedRequest

@property (strong, nonatomic) WLWrap* wrap;

+ (instancetype)request:(WLWrap*)wrap;

@end
