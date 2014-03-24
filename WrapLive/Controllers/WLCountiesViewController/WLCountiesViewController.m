//
//  WLCountiesViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 24.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCountiesViewController.h"
#import "WLCountry.h"

@interface WLCountiesViewController ()

@property (strong, nonatomic) void (^completionBlock) (WLCountry* country);

@end

@implementation WLCountiesViewController

+ (void)show:(void (^)(WLCountry *))completion {
	[[[WLCountiesViewController alloc] init] show:completion];
}

- (void)show:(void (^)(WLCountry *))completion {
	self.completionBlock = completion;
}

- (void)hide {
	
}

@end
