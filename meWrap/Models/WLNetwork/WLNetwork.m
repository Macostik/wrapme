//
//  WLNetwork.m
//  meWrap
//
//  Created by Ravenpod on 5/7/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLNetwork.h"
#import "AFNetworkReachabilityManager.h"
#import "WLUploadingQueue.h"

@implementation WLNetwork

+ (instancetype)sharedNetwork {
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
    [[DispatchQueue mainQueue] runAfter:0.2 block:^{
        [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            if (weakSelf.reachable) {
                [WLUploadingQueue start];
            }
            for (id receiver in [weakSelf broadcastReceivers]) {
                if ([receiver respondsToSelector:@selector(networkDidChangeReachability:)]) {
                    [receiver networkDidChangeReachability:weakSelf];
                }
            }
            if (weakSelf.changeReachabilityBlock) {
                weakSelf.changeReachabilityBlock(weakSelf);
            }
        }];
    }];
}

@end
