//
//  WLGradientDrawer.m
//  WrapLive
//
//  Created by Sergey Maximenko on 1/13/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLGradientDrawer.h"

@implementation WLGradientDrawer

static NSMutableDictionary *images = nil;

+ (NSMutableDictionary*)imagesCache {
    if (!images) {
        images = [NSMutableDictionary dictionary];
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            [images removeAllObjects];
        }];
    }
    return images;
}

+ (UIImage *)drawImageWithSize:(CGFloat)size color:(UIColor *)color mode:(UIViewContentMode)mode {
    CGSize imageSize;
    switch (mode) {
        case UIViewContentModeTop:
            imageSize = CGSizeMake(1, size);
            break;
        case UIViewContentModeLeft:
            imageSize = CGSizeMake(size, 1);
            break;
        case UIViewContentModeRight:
            imageSize = CGSizeMake(size, 1);
            break;
        default:
            imageSize = CGSizeMake(1, size);
            break;
    }
    
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, [UIScreen mainScreen].scale);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGGradientRef gradient = CGGradientCreateWithColors(NULL, (__bridge CFArrayRef)(@[(id)color.CGColor, (id)[color colorWithAlphaComponent:0.0f].CGColor]), NULL);
    
    switch (mode) {
        case UIViewContentModeTop:
            CGContextDrawLinearGradient(ctx, gradient, CGPointMake(0.5, 0), CGPointMake(0.5, size), 0);
            break;
        case UIViewContentModeLeft:
            CGContextDrawLinearGradient(ctx, gradient, CGPointMake(0, 0.5), CGPointMake(size, 0.5), 0);
            break;
        case UIViewContentModeRight:
            CGContextDrawLinearGradient(ctx, gradient, CGPointMake(size, 0.5), CGPointMake(0, 0.5), 0);
            break;
        default:
            CGContextDrawLinearGradient(ctx, gradient, CGPointMake(0.5, size), CGPointMake(0.5, 0), 0);
            break;
    }
    
    CGGradientRelease(gradient);
    
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)imageWithSize:(CGFloat)size color:(UIColor *)color mode:(UIViewContentMode)mode {
    
    CGFloat r,g,b,a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    
    NSString *key = [NSString stringWithFormat:@"%f-%f-%f-%f-%f-%d", size, r, g, b, a, mode];
    
    UIImage *image = [[self imagesCache] objectForKey:key];
    
    if (image) return image;
    
    image = [self drawImageWithSize:size color:color mode:mode];
    
    [[self imagesCache] setObject:image forKey:key];
    
    return image;
}

@end
