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
	for (id <WLWrapBroadcastReceiver> receiver in self.receivers) {
		if ([receiver respondsToSelector:@selector(broadcaster:wrapChanged:)]) {
			[receiver broadcaster:self wrapChanged:wrap];
		}
	}
}

- (void)broadcastCreation:(WLWrap *)wrap {
	for (id <WLWrapBroadcastReceiver> receiver in self.receivers) {
		if ([receiver respondsToSelector:@selector(broadcaster:wrapCreated:)]) {
			[receiver broadcaster:self wrapCreated:wrap];
		}
	}
}

@end
