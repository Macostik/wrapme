//
//  WLInternetConnectionBroadcaster.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 5/7/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLInternetConnectionBroadcaster.h"
#import <Reachability/Reachability.h>
#import "WLBlocks.h"
#import "WLToast.h"

@implementation WLInternetConnectionBroadcaster

+ (instancetype)broadcaster {
    static id instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[self alloc] init];
	});
    return instance;
}

+ (Reachability*)reachability {
	static Reachability *reachability = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		reachability = [Reachability reachabilityForInternetConnection];
	});
	return reachability;
}

- (void)configure {
	[self performSelector:@selector(showLostConnectionBannerIfNeeded) withObject:nil afterDelay:0.5f];
}

- (BOOL)reachable {
	return [[WLInternetConnectionBroadcaster reachability] isReachable];
}

- (void)setup {
	__weak typeof(self)weakSelf = self;
	Reachability* reachability = [WLInternetConnectionBroadcaster reachability];
	[reachability startNotifier];
	NetworkReachable reachabilityChangedBlock = ^(Reachability* reachability) {
		run_in_main_queue(^{
			[weakSelf broadcast:@selector(broadcaster:internetConnectionReachable:) object:@(weakSelf.reachable)];
			[weakSelf showLostConnectionBannerIfNeeded];
		});
	};
	[reachability setReachableBlock:reachabilityChangedBlock];
	[reachability setUnreachableBlock:reachabilityChangedBlock];
}

- (void)showLostConnectionBannerIfNeeded {
	if (![WLInternetConnectionBroadcaster broadcaster].reachable) {
		[self showLostConnectionBanner];
	}
}

- (void)showLostConnectionBanner {
	[WLToast showWithMessage:@"Internet connection unavailable"];
}

@end
