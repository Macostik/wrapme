//
//  WLCandy.m
//  WrapLive
//
//  Created by Sergey Maximenko on 13.06.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCandy.h"
#import "WLComment.h"
#import "WLWrap.h"


@implementation WLCandy

@dynamic type;
@dynamic commentCount;
@dynamic wrap;
@dynamic comments;

@synthesize downloadSuccessBlock = _downloadSuccessBlock;
@synthesize downloadFailureBlock = _downloadFailureBlock;

@end
