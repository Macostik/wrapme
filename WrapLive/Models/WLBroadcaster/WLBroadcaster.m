//
//  WLBroadcaster.m
//  WrapLive
//
//  Created by Sergey Maximenko on 24.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBroadcaster.h"

@interface WLBroadcaster ()

@property (strong, nonatomic) NSHashTable* receivers;

@end

@implementation WLBroadcaster

+ (instancetype)broadcaster {
    return nil;
}

- (NSHashTable *)receivers {
	if (!_receivers) {
		_receivers = [NSHashTable weakObjectsHashTable];
	}
	return _receivers;
}

- (void)addReceiver:(id<WLBroadcastReceiver>)receiver {
	if (![self containsReceiver:receiver]) {
		[self.receivers addObject:receiver];
	}
}

- (BOOL)containsReceiver:(id<WLBroadcastReceiver>)receiver {
	for (id <WLBroadcastReceiver> _receiver in self.receivers) {
		if (_receiver == receiver) {
			return YES;
		}
	}
	return NO;
}

@end
