//
//  WLDrawingSession.h
//  wrapLive
//
//  Created by Sergey Maximenko on 6/24/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLDrawingBrush.h"
#import "WLDrawingLine.h"

@class WLDrawingSession;

@protocol WLDrawingSessionDelegate <NSObject>

@optional
- (void)drawingSessionDidBeginDrawing:(WLDrawingSession*)session;

- (void)drawingSession:(WLDrawingSession*)session didEndDrawing:(WLDrawingLine*)line;

@end

@interface WLDrawingSession : NSObject

@property (strong, nonatomic) WLDrawingBrush *brush;

@property (nonatomic, weak) id <WLDrawingSessionDelegate> delegate;

@property (strong, nonatomic) NSMutableArray* lines;

@property (nonatomic, readonly) BOOL empty;

@property (weak, nonatomic, readonly) WLDrawingLine* line;

@property (nonatomic) BOOL drawing;

- (void)render:(BOOL)approximated;

- (void)undo;

- (WLDrawingLine*)beginDrawing;

- (void)addPoint:(CGPoint)point;

- (void)endDrawing;

@end
