//
//  WLWrapBroadcaster.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapBroadcaster.h"

@interface WLWrapBroadcaster ()

@property (strong, nonatomic) NSHashTable* receivers;

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

- (NSHashTable *)receivers {
	if (!_receivers) {
		_receivers = [NSHashTable weakObjectsHashTable];
	}
	return _receivers;
}

- (void)addReceiver:(id<WLWrapBroadcastReceiver>)receiver {
	if (![self containsReceiver:receiver]) {
		[self.receivers addObject:receiver];
	}
}

- (BOOL)containsReceiver:(id<WLWrapBroadcastReceiver>)receiver {
	for (id <WLWrapBroadcastReceiver> _receiver in self.receivers) {
		if (_receiver == receiver) {
			return YES;
		}
	}
	return NO;
}

- (void)broadcastChange:(WLWrap *)wrap {
	for (id <WLWrapBroadcastReceiver> receiver in self.receivers) {
		if ([receiver respondsToSelector:@selector(wrapBroadcaster:wrapChanged:)]) {
			[receiver wrapBroadcaster:self wrapChanged:wrap];
		}
	}
}

- (void)broadcastCreation:(WLWrap *)wrap {
	for (id <WLWrapBroadcastReceiver> receiver in self.receivers) {
		if ([receiver respondsToSelector:@selector(wrapBroadcaster:wrapCreated:)]) {
			[receiver wrapBroadcaster:self wrapCreated:wrap];
		}
	}
}

@end
