//
//  WLNetwork.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 5/7/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLNetwork.h"
#import "WLToast.h"
#import "WLUploading+Extended.h"
#import "WLAPIManager.h"
#import "WLAuthorizationRequest.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>

@implementation WLNetwork

+ (instancetype)network {
    static id instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[self alloc] init];
	});
    return instance;
}

- (void)configure {
	[self performSelector:@selector(showLostConnectionBannerIfNeeded) withObject:nil afterDelay:0.5f];
}

- (BOOL)reachable {
	return [AFNetworkReachabilityManager sharedManager].reachable;
}

- (void)setup {
    [super setup];
	__weak typeof(self)weakSelf = self;
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        [weakSelf broadcast:@selector(networkDidChangeReachability:)];
        [weakSelf showLostConnectionBannerIfNeeded];
        if (weakSelf.reachable) {
            if ([WLAuthorizationRequest authorized]) {
                [WLUploading enqueueAutomaticUploading:^{
                }];
            } else {
                [[WLAuthorizationRequest signInRequest] send];
            }
        }
    }];
}

- (void)showLostConnectionBannerIfNeeded {
    AFNetworkReachabilityStatus status = [AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;
	if (status == AFNetworkReachabilityStatusNotReachable) {
		[WLToast showWithMessage:@"Internet connection unavailable"];
	}
}

@end
