//
//  WLUpdateContributorsRequest.h
//  WrapLive
//
//  Created by Yura Granchenko on 9/10/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAPIRequest.h"

@interface WLUpdateContributorsRequest : WLAPIRequest

@property (weak, nonatomic) WLWrap* wrap;

@property (strong, nonatomic) NSArray *contributors;

@property (nonatomic) BOOL isAddContirbutor;

+ (instancetype)request:(WLWrap*)wrap;

@end
