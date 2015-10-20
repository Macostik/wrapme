//
//  UIImage+Drawing.h
//  meWrap
//
//  Created by Ravenpod on 11/4/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Drawing)

+ (UIImage*)draw:(CGSize)size opaque:(BOOL)opaque scale:(CGFloat)scale drawing:(void(^)(CGSize size))drawing;

+ (void)drawAssetNamed:(NSString*)name directory:(NSString*)directory size:(CGSize)size opaque:(BOOL)opaque drawing:(void(^)(CGSize size))drawing;

+ (void)drawAssetNamed:(NSString*)name directory:(NSString*)directory size:(CGSize)size drawing:(void(^)(CGSize size))drawing;

@end
