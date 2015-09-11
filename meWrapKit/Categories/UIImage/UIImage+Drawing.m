//
//  UIImage+Drawing.m
//  meWrap
//
//  Created by Ravenpod on 11/4/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "UIImage+Drawing.h"
#import "NSString+Documents.h"
#import "PHPhotoLibrary+Helper.h"
#import "GCDHelper.h"

@implementation UIImage (Drawing)

+ (UIImage *)draw:(CGSize)size opaque:(BOOL)opaque scale:(CGFloat)scale drawing:(void (^)(CGSize))drawing {
    
    if (!drawing) return nil;
    
    UIGraphicsBeginImageContextWithOptions(size, opaque, scale);
    
    drawing(size);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

+ (void)drawAssetNamed:(NSString*)name directory:(NSString*)directory size:(CGSize)size opaque:(BOOL)opaque drawing:(void (^)(CGSize))drawing {
    NSArray* scales = @[@1,@2,@3];
    for (NSNumber* scale in scales) {
        UIGraphicsBeginImageContextWithOptions(size, opaque, [scale floatValue]);
        drawing(size);
        NSData *data = UIImagePNGRepresentation(UIGraphicsGetImageFromCurrentImageContext());
        if ([scale floatValue] == 1) {
            [data writeToFile:[directory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", name]] atomically:NO];
        } else {
            [data writeToFile:[directory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@@%@x.png", name, scale]] atomically:NO];
        }
        
        UIGraphicsEndImageContext();
    }
}

+ (void)drawAssetNamed:(NSString *)name directory:(NSString *)directory size:(CGSize)size drawing:(void (^)(CGSize))drawing {
    [self drawAssetNamed:name directory:directory size:size opaque:YES drawing:drawing];
}

- (void)writeToPNGFile:(NSString *)path atomically:(BOOL)atomically {
    [UIImagePNGRepresentation(self) writeToFile:path atomically:atomically];
}

+ (UIImage*)gradient:(CGSize)size {
    return [self draw:size opaque:NO scale:1 drawing:^(CGSize size) {
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        
        CFArrayRef colors = (__bridge CFArrayRef) @[(id)[UIColor blackColor].CGColor, (id)[[UIColor blackColor] colorWithAlphaComponent:0.0].CGColor];
        
        CGGradientRef gradient = CGGradientCreateWithColors(NULL, colors, NULL);
        
        CGContextDrawLinearGradient(ctx, gradient, CGPointMake(size.width/2, size.height), CGPointMake(size.width/2, 0.0), kCGGradientDrawsAfterEndLocation);
        
        CGGradientRelease(gradient);
    }];
}

@end
