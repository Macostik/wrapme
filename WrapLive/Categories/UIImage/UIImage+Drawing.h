//
//  UIImage+Drawing.h
//  WrapLive
//
//  Created by Sergey Maximenko on 11/4/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Drawing)

+ (void)drawAssetNamed:(NSString*)name directory:(NSString*)directory size:(CGSize)size drawing:(void(^)(CGSize size))drawing;

@end
