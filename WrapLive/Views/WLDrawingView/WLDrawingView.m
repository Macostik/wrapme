//
//  WLDrawingView.m
//  wrapLive
//
//  Created by Sergey Maximenko on 6/23/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLDrawingView.h"
#import "WLButton.h"
#import "WLDrawingCanvas.h"
#import "WLDrawingSession.h"
#import "WLColorPicker.h"

@interface WLDrawingView () <WLDrawingSessionDelegate, WLColorPickerDelegate>

@property (strong, nonatomic) WLDrawingSession *session;
@property (weak, nonatomic) WLDrawingCanvas *canvas;
@property (weak, nonatomic) IBOutlet UIButton *undoButton;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet WLDrawingCanvas *brushCanvas;
@property (weak, nonatomic) IBOutlet UIView *colorsView;

@property (strong, nonatomic) NSArray* colors;

@end

@implementation WLDrawingView

- (void)setImage:(UIImage *)image {
    self.imageView.image = image;
    self.imageView.userInteractionEnabled = YES;
    CGRect drawingRect = CGRectThatFitsSize(self.imageView.size, self.imageView.image.size);
    WLDrawingCanvas* canvas = [[WLDrawingCanvas alloc] initWithFrame:drawingRect];
    self.canvas = canvas;
    canvas.opaque = NO;
    canvas.backgroundColor = [UIColor clearColor];
    [self.imageView addSubview:canvas];
    [self.imageView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:canvas action:@selector(panning:)]];
    [canvas addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:canvas action:@selector(panning:)]];
    
    self.session = self.canvas.session;
    self.session.delegate = self;
    self.session.interpolated = NO;
    self.session.brush = [WLDrawingBrush brushWithColor:[UIColor redColor] width:24];
    
    [self updateBrushView];
}

- (IBAction)cancel:(id)sender {
    if ([self.delegate respondsToSelector:@selector(drawingViewDidCancel:)]) {
        [self.delegate drawingViewDidCancel:self];
    }
}

- (IBAction)decreaseBrush:(UIButton*)sender {
    CGFloat size = self.session.brush.width;
    if (size > 3) {
        self.session.brush.width = size - 0.3f;
        [self updateBrushView];
        
        if (sender.tracking && sender.touchInside) {
            [self performSelector:@selector(decreaseBrush:) withObject:sender afterDelay:0.0f];
        }
    }
}

- (IBAction)increaseBrush:(UIButton*)sender {
    CGFloat size = self.session.brush.width;
    if (size < 51) {
        self.session.brush.width = size + 0.3f;
        [self updateBrushView];
        
        if (sender.tracking && sender.touchInside) {
            [self performSelector:@selector(increaseBrush:) withObject:sender afterDelay:0.0f];
        }
    }
}

- (void)updateBrushView {
    WLDrawingSession *session = self.brushCanvas.session;
    [session erase];
    session.brush = self.session.brush;
    [session beginDrawing];
    [session addPoint:self.brushCanvas.centerBoundary];
    [session endDrawing];
    [self.brushCanvas setNeedsDisplay];
}

- (IBAction)undo:(id)sender {
    [self.session undo];
    [self.canvas setNeedsDisplay];
    self.undoButton.hidden = self.session.empty;
}

- (IBAction)finish:(WLButton *)sender {
    if ([self.delegate respondsToSelector:@selector(drawingView:didFinishWithImage:)]) {
        __weak typeof(self)weakSelf = self;
        
        UIImage *image = self.imageView.image;
        
        if (self.session.empty) {
            [self.delegate drawingViewDidCancel:self];
            return;
        }
        
        CGSize size = image.size;
        image = [UIImage draw:size opaque:NO scale:1 drawing:^(CGSize size) {
            [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
            CGContextScaleCTM(UIGraphicsGetCurrentContext(), size.width / weakSelf.canvas.width, size.height / weakSelf.canvas.height);
            [weakSelf.session render];
        }];
        [self.delegate drawingView:self didFinishWithImage:image];
    }
}

// MARK: - WLDrawingSessionDelegate

- (void)drawingSession:(WLDrawingSession *)session didEndDrawing:(WLDrawingLine *)line {
    [line interpolate];
    self.undoButton.hidden = session.empty;
}

// MARK: - WLColorPickerDelegate

- (void)colorPicker:(WLColorPicker *)picker pickedColor:(UIColor *)color {
    self.session.brush.color = color;
    [self updateBrushView];
}

@end
