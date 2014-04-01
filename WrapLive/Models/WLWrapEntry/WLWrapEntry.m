//
//  WLWrapEntry.m
//  WrapLive
//
//  Created by Sergey Maximenko on 01.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapEntry.h"
#import "WLSession.h"

@implementation WLWrapEntry

+ (instancetype)entry {
	WLWrapEntry* entry = [super entry];
	entry.author = [WLSession user];
	return entry;
}

@end
