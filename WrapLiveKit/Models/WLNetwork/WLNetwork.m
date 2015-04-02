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
#import "WLUploadingQueue.h"

@implementation WLNetwork

+ (instancetype)network {
    static id instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[self alloc] init];
	});
    return instance;
}

- (BOOL)reachable {
	return [AFNetworkReachabilityManager sharedManager].reachable;
}

- (void)setup {
    [super setup];
	__weak typeof(self)weakSelf = self;
    AFNetworkReachabilityManager* manager = [AFNetworkReachabilityManager sharedManager];
    [manager startMonitoring];
    run_after(0.2, ^{
        [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            [weakSelf broadcast:@selector(networkDidChangeReachability:)];
            if (weakSelf.changeReachabilityBlock) {
                weakSelf.changeReachabilityBlock(weakSelf);
            }
        }];
    });
}

@end
