//
//  WLDrawingSessionView.m
//  wrapLive
//
//  Created by Sergey Maximenko on 6/24/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLDrawingCanvas.h"
#import "WLDrawingSession.h"

@interface WLDrawingCanvas ()

@end

@implementation WLDrawingCanvas

- (void)drawRect:(CGRect)rect {
    [self.session render:YES];
}

- (IBAction)panning:(UIPanGestureRecognizer*)sender {
    
    UIGestureRecognizerState state = sender.state;
    
    if (!self.session.drawing) {
        [self.session beginDrawing];
    }
    
    [self.session addPoint:[sender locationInView:self]];
    [self setNeedsDisplay];
    
    if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled) {
        [self.session endDrawing];
    }
}

@end
