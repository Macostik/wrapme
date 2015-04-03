//
//  WLCandiesRequest.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPaginatedRequest.h"

static NSString* WLCandiesOrderByCreation = @"contributed_at";
static NSString* WLCandiesOrderByUpdating = @"last_touched_at";

@interface WLCandiesRequest : WLPaginatedRequest

@property (weak, nonatomic) WLWrap* wrap;

@property (strong, nonatomic) NSString* orderBy;

+ (instancetype)request:(WLWrap*)wrap;

@end
