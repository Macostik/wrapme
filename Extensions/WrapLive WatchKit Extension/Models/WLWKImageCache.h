//
//  WLWKImageCache.h
//  WrapLive
//
//  Created by Sergey Maximenko on 1/23/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface WLWKImageCache : NSObject

+ (void)imageWithURL:(NSString*)url completion:(void (^)(UIImage *image))completion;

+ (void)imageWithURL:(NSString*)url edit:(UIImage* (^)(UIImage* image))edit completion:(void (^)(UIImage *image))completion;

@end

@interface UIImage (WLWKAdditions)

- (UIImage*)circleImage;

@end
