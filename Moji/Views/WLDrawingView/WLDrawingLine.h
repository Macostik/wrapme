//
//  WLDrawingLine.h
//  moji
//
//  Created by Ravenpod on 6/24/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLDrawingBrush;

@interface WLDrawingLine : NSObject

@property (copy, nonatomic) WLDrawingBrush* brush;

@property (nonatomic) BOOL completed;

@property (strong, nonatomic) UIBezierPath* path;

- (void)addPoint:(CGPoint)point;

- (void)render;

- (void)interpolate;

- (BOOL)intersectsRect:(CGRect)rect;

@end
