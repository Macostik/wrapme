//
//  WLWrapBroadcaster.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapBroadcaster.h"

@interface WLWrapBroadcaster ()

@end

@implementation WLWrapBroadcaster

+ (instancetype)broadcaster {
    static id instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[self alloc] init];
	});
    return instance;
}

- (void)broadcastChange:(WLWrap *)wrap {
	[self broadcast:@selector(broadcaster:wrapChanged:) object:wrap];
}

- (void)broadcastCreation:(WLWrap *)wrap {
	[self broadcast:@selector(broadcaster:wrapCreated:) object:wrap];
}

- (void)broadcastCandyChange:(WLCandy *)candy {
	[self broadcast:@selector(broadcaster:candyChanged:) object:candy];
}

@end
