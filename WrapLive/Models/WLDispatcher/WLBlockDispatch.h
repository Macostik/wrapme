//
//  WLBlockDispatch.h
//  WrapLive
//
//  Created by Sergey Maximenko on 9/8/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLDispatch.h"
#import "WLBlocks.h"

@interface WLBlockDispatch : WLDispatch

@property (strong, nonatomic) WLBlock block;

+ (instancetype)dispatch:(WLBlock)block;

- (id)initWithBlock:(WLBlock)block;

@end
