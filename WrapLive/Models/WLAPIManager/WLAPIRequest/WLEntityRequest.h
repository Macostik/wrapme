//
//  WLEntityRequest.h
//  WrapLive
//
//  Created by Sergey Maximenko on 9/12/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAPIRequest.h"

@interface WLEntityRequest : WLAPIRequest

@property (strong, nonatomic) WLEntry* entry;

+ (instancetype)request:(WLEntry *)entry;

@end
