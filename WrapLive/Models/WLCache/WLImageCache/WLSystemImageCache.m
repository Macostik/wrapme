//
//  WLSystemImageCache.m
//  WrapLive
//
//  Created by Sergey Maximenko on 14.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLSystemImageCache.h"

@implementation WLSystemImageCache

+ (instancetype)instance {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
		__weak typeof(self)weakSelf = self;
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
			[weakSelf removeAllObjects];
		}];
    }
    return self;
}

+ (UIImage*)imageWithIdentifier:(NSString*)identifier {
	return [[self instance] imageWithIdentifier:identifier];
}

+ (void)setImage:(UIImage*)image withIdentifier:(NSString*)identifier {
	[[self instance] setImage:image withIdentifier:identifier];
}

- (UIImage*)imageWithIdentifier:(NSString*)identifier {
	return [self objectForKey:identifier];
}

- (void)setImage:(UIImage*)image withIdentifier:(NSString*)identifier {
	if (image) {
		[self setObject:image forKey:identifier];
	}
}

@end
