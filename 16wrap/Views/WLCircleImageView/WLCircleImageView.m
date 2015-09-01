//
//  WLCircleImageView.m
//  moji
//
//  Created by Ravenpod on 11/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCircleImageView.h"

@implementation WLCircleImageView

- (void)awakeFromNib {
    [super awakeFromNib];
    UIImageView *circle = [[UIImageView alloc] initWithFrame:self.bounds];
    circle.backgroundColor = [UIColor clearColor];
    circle.image = [self circleImage];
    [self addSubview:circle];
}

- (UIImage*)circleImage {
    static NSMutableDictionary* circles = nil;
    if (!circles) {
        circles = [NSMutableDictionary dictionary];
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            [circles removeAllObjects];
        }];
    }
    CGRect bounds = self.bounds;
    UIImage* circle = [circles objectForKey:@(bounds.size.height)];
    if (!circle) {
        UIGraphicsBeginImageContextWithOptions(bounds.size, NO, [UIScreen mainScreen].scale);
        UIBezierPath * path = [UIBezierPath bezierPathWithRect:bounds];
        [[UIColor whiteColor] setFill];
        [path fill];
        path = [UIBezierPath bezierPathWithOvalInRect:bounds];
        [path fillWithBlendMode:kCGBlendModeClear alpha:0];
        circle = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [circles setObject:circle forKey:@(bounds.size.height)];
    }
    return circle;
}

@end
