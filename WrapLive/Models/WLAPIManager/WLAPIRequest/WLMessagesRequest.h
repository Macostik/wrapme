//
//  WLMessagesRequest.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPaginatedRequest.h"

@interface WLMessagesRequest : WLPaginatedRequest

@property (weak, nonatomic) WLWrap* wrap;

@property (nonatomic) BOOL latest;

+ (instancetype)request:(WLWrap*)wrap;

@end
