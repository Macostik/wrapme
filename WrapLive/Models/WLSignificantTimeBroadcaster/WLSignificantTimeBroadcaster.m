//
//  WLSignificantTimeBroadcaster.m
//  WrapLive
//
//  Created by Yura Granchenko on 7/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLSignificantTimeBroadcaster.h"

@implementation WLSignificantTimeBroadcaster

+ (instancetype)broadcaster {
    static id instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[self alloc] init];
	});
    return instance;
}

- (void)setup {
    [super setup];
    [self setupNotificationByTheName:UIApplicationSignificantTimeChangeNotification];
    [self setupNotificationByTheName:NSSystemTimeZoneDidChangeNotification];
}

- (void)setupNotificationByTheName:(NSString *)name {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangeSignificantTime:)
                                                 name:name
                                               object:nil];
}

- (void)didChangeSignificantTime:(NSNotification *) notification {
    [self broadcast:@selector(broadcaster:didChangeSignificantTime:) object:notification];
}

@end
