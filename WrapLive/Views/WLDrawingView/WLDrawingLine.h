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

@property (strong, nonatomic) NSMutableArray* points;

- (void)addPoint:(CGPoint)point;

- (void)render:(BOOL)approximated;

@end
