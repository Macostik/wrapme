//
//  WLSystemImageCache.h
//  meWrap
//
//  Created by Ravenpod on 14.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLSystemImageCache : NSCache

+ (instancetype)instance;

+ (UIImage*)imageWithIdentifier:(NSString*)identifier;

+ (void)setImage:(UIImage*)image withIdentifier:(NSString*)identifier;

+ (void)removeImageWithIdentifier:(NSString*)identifier;

- (UIImage*)imageWithIdentifier:(NSString*)identifier;

- (void)setImage:(UIImage*)image withIdentifier:(NSString*)identifier;

- (void)removeImageWithIdentifier:(NSString*)identifier;

@end
