//
//  WLDrawingLine.h
//  wrapLive
//
//  Created by Sergey Maximenko on 6/24/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLDrawingBrush;

@interface WLDrawingLine : NSObject

@property (copy, nonatomic) WLDrawingBrush* brush;

@property (nonatomic) BOOL completed;

- (void)addPoint:(CGPoint)point;

- (void)render;

- (void)interpolate;

@end
