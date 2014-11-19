//
//  UIImage+Drawing.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11/4/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "UIImage+Drawing.h"
#import "NSString+Documents.h"

@implementation UIImage (Drawing)

+ (void)drawAssetNamed:(NSString*)name directory:(NSString*)directory size:(CGSize)size drawing:(void(^)(CGSize size))drawing {
    NSArray* scales = @[@1,@2,@3];
    for (NSNumber* scale in scales) {
        UIGraphicsBeginImageContextWithOptions(size, YES, [scale floatValue]);
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

@end
