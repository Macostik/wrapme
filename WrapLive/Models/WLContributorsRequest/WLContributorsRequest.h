//
//  WLContributorsRequest.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAPIRequest.h"

@interface WLContributorsRequest : WLAPIRequest

@property (strong, nonatomic) NSArray* contacts;

+ (instancetype)request:(NSArray*)contacts;

@end
