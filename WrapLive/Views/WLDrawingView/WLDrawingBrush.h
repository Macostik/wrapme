//
//  WLDrawingBrush.h
//  wrapLive
//
//  Created by Sergey Maximenko on 6/24/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLDrawingBrush : NSObject <NSCopying>

@property (nonatomic) CGFloat width;

@property (nonatomic) CGFloat opacity;

@property (strong, nonatomic) UIColor* color;

+ (instancetype)brushWithColor:(UIColor*)color width:(CGFloat)width;

- (BOOL)isEqualToBrush:(WLDrawingBrush*)brush;

@end
