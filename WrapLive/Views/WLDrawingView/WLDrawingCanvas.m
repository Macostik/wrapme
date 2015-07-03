//
//  WLDrawingSessionView.m
//  wrapLive
//
//  Created by Sergey Maximenko on 6/24/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLDrawingCanvas.h"
#import "WLDrawingSession.h"
#import "UIView+Extentions.h"

@interface WLDrawingCanvas ()

@property (weak, nonatomic) UIImageView *imageView;

@end

@implementation WLDrawingCanvas

- (void)dealloc {
    if (self.imageView) {
        [self.imageView removeFromSuperview];
    }
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.session = [[WLDrawingSession alloc] init];
}

- (UIImageView *)imageView {
    if (!_imageView) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.frame];
        [self.superview insertSubview:imageView belowSubview:self];
        [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
        [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
        _imageView = imageView;
    }
    return _imageView;
}

- (void)drawRect:(CGRect)rect {
    [self.session.line render];
}

- (IBAction)panning:(UIPanGestureRecognizer*)sender {
    
    UIGestureRecognizerState state = sender.state;
    
    if (!self.session.drawing) {
        [self.session beginDrawing];
    }
    
    [self.session addPoint:[sender locationInView:self]];
    
    if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled) {
        [self.session endDrawing];
        [self render];
    }
    
    [self setNeedsDisplay];
}

- (void)render {
    __weak typeof(self)weakSelf = self;
    self.imageView.image = [UIImage draw:self.size opaque:NO scale:[UIScreen mainScreen].scale drawing:^(CGSize size) {
        [weakSelf.session render];
    }];
}

- (void)undo {
    [self.session undo];
    [self render];
}

- (void)erase {
    [self.session erase];
    self.imageView.image = nil;
}

@end
