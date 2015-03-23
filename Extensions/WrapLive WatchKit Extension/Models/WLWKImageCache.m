//
//  WLWKImageCache.m
//  WrapLive
//
//  Created by Sergey Maximenko on 1/23/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWKImageCache.h"
#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@implementation WLWKImageCache

+ (void)imageWithURL:(NSString *)url completion:(void (^)(UIImage *))completion {
    [self imageWithURL:url edit:nil completion:completion];
}

+ (void)imageWithURL:(NSString *)url edit:(UIImage *(^)(UIImage *))edit completion:(void (^)(UIImage *))completion {
    if (!url) {
        return;
    }
    static NSCache *cache = nil;
    
    if (cache == nil) {
        cache = [[NSCache alloc] init];
        cache.totalCostLimit = 10;
    }
    
    __block UIImage *image = [cache objectForKey:url];
    if (image) {
        if (completion) completion(image);
    } else {
        static NSMutableDictionary *completionBlocks = nil;
        if (!completionBlocks) {
            completionBlocks = [NSMutableDictionary dictionary];
        }
        
        NSMutableSet *blocks = completionBlocks[url];
        
        if (completion) {
            if (!blocks) {
                blocks = completionBlocks[url] = [NSMutableSet set];
            }
            [blocks addObject:completion];
        }
        
        if (blocks.count > 1) {
            return;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
            image = [UIImage imageWithData:data];
            if (edit) {
                image = edit(image);
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [cache setObject:image forKey:url cost:1];
                NSMutableSet *blocks = completionBlocks[url];
                for (void (^completion)(UIImage *) in blocks) {
                    completion(image);
                }
            });
        });
    }
}

@end

@implementation UIImage (WLWKAdditions)

- (UIImage*)circleImage {
    CGSize size = self.size;
    UIGraphicsBeginImageContext(size);
    [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, size.width, size.height)] addClip];
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
