//
//  WLLoadingView.m
//  WrapLive
//
//  Created by Sergey Maximenko on 09.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLLoadingView.h"
#import "NSObject+NibAdditions.h"

@implementation WLLoadingView

+ (instancetype)instance {
    static id instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [self loadFromNib];
	});
    return instance;
}

@end
