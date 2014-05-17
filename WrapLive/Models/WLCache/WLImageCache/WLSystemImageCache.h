//
//  WLSystemImageCache.h
//  WrapLive
//
//  Created by Sergey Maximenko on 14.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLSystemImageCache : NSCache

+ (instancetype)instance;

+ (UIImage*)imageWithIdentifier:(NSString*)identifier;

+ (void)setImage:(UIImage*)image withIdentifier:(NSString*)identifier;

- (UIImage*)imageWithIdentifier:(NSString*)identifier;

- (void)setImage:(UIImage*)image withIdentifier:(NSString*)identifier;

@end
