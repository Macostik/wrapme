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

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.session = [[WLDrawingSession alloc] init];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.session = [[WLDrawingSession alloc] init];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [self.session render];
}

- (IBAction)panning:(UIPanGestureRecognizer*)sender {
    
    UIGestureRecognizerState state = sender.state;
    
    if (!self.session.drawing) {
        [self.session beginDrawing];
    }
    
    [self.session addPoint:[sender locationInView:self]];
    
    if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled) {
        [self.session endDrawing];
    }
    
    [self setNeedsDisplay];
}

@end
