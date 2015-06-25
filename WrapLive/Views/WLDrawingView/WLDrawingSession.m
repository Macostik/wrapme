//
//  WLDrawingSession.m
//  wrapLive
//
//  Created by Sergey Maximenko on 6/24/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLDrawingSession.h"

@interface WLDrawingSession ()

@property (weak, nonatomic) WLDrawingLine* line;

@end

@implementation WLDrawingSession

- (instancetype)init {
    self = [super init];
    if (self) {
        self.lines = [NSMutableArray array];
    }
    return self;
}

- (BOOL)empty {
    return self.lines.count == 0;
}

- (void)undo {
    [self.lines removeLastObject];
}

- (void)render {
    for (WLDrawingLine *line in self.lines) {
        [line render];
    }
}

- (WLDrawingLine*)beginDrawing {
    WLDrawingLine *line = [[WLDrawingLine alloc] init];
    line.brush = self.brush;
    [self.lines addObject:line];
    self.line = line;
    if ([self.delegate respondsToSelector:@selector(drawingSessionDidBeginDrawing:)]) {
        [self.delegate drawingSessionDidBeginDrawing:self];
    }
    self.drawing = YES;
    return line;
}

- (void)addPoint:(CGPoint)point {
    [self.line addPoint:point];
}

- (void)endDrawing {
    self.drawing = NO;
    if ([self.delegate respondsToSelector:@selector(drawingSession:didEndDrawing:)]) {
        [self.delegate drawingSession:self didEndDrawing:self.line];
    }
    if (self.interpolated) {
        [self.line interpolate];
    }
    self.line.completed = YES;
    self.line = nil;
}

- (void)erase {
    [self.lines removeAllObjects];
    self.line = nil;
    self.drawing = NO;
}

@end
