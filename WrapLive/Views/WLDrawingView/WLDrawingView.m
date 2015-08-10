//
//  WLDrawingView.m
//  moji
//
//  Created by Ravenpod on 6/23/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLDrawingView.h"
#import "WLButton.h"
#import "WLDrawingCanvas.h"
#import "WLDrawingSession.h"
#import "WLColorPicker.h"
#import "UIView+LayoutHelper.h"

@interface WLDrawingView () <WLDrawingSessionDelegate, WLColorPickerDelegate, WLDrawingViewDelegate>

@property (strong, nonatomic) WLDrawingSession *session;
@property (weak, nonatomic) WLDrawingCanvas *canvas;
@property (weak, nonatomic) IBOutlet UIButton *undoButton;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet WLDrawingCanvas *brushCanvas;
@property (weak, nonatomic) IBOutlet UIView *colorsView;

@property (strong, nonatomic) NSArray* colors;

@property (strong, nonatomic) WLImageBlock doneBlock;

@property (strong, nonatomic) WLBlock cancelBlock;

@end

@implementation WLDrawingView

- (void)showInView:(UIView *)view {
    self.frame = view.bounds;
    [view addSubview:self];
    [view makeResizibleSubview:self];
}

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
    self.session.brush = [WLDrawingBrush brushWithColor:[UIColor redColor] width:10];
    
    [self updateBrushView];
}

- (void)setImage:(UIImage *)image done:(WLImageBlock)done cancel:(WLBlock)cancel {
    [self setImage:image];
    self.delegate = self;
    self.doneBlock = done;
    self.cancelBlock = cancel;
}

- (IBAction)cancel:(id)sender {
    if ([self.delegate respondsToSelector:@selector(drawingViewDidCancel:)]) {
        [self.delegate drawingViewDidCancel:self];
    }
}

- (IBAction)decreaseBrush:(UIButton*)sender {
    CGFloat size = self.session.brush.width;
    if (size > 3) {
        self.session.brush.width = size - 0.25f;
        [self updateBrushView];
        
        if (sender.tracking && sender.touchInside) {
            [self performSelector:@selector(decreaseBrush:) withObject:sender afterDelay:0.0f];
        }
    }
}

- (IBAction)increaseBrush:(UIButton*)sender {
    CGFloat size = self.session.brush.width;
    if (size < 51) {
        self.session.brush.width = size + 0.25f;
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
    [self.brushCanvas render];
}

- (IBAction)undo:(id)sender {
    [self.canvas undo];
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

- (BOOL)drawingSession:(WLDrawingSession *)session isAcceptableLine:(WLDrawingLine *)line {
    return [line intersectsRect:CGRectInset(self.canvas.bounds, -line.brush.width/2, -line.brush.width/2)];
}

// MARK: - WLColorPickerDelegate

- (void)colorPicker:(WLColorPicker *)picker pickedColor:(UIColor *)color {
    self.session.brush.color = color;
    [self updateBrushView];
}

// MARK: - WLDrawingViewDelegate

- (void)drawingViewDidCancel:(WLDrawingView *)view {
    if (self.cancelBlock) {
        self.cancelBlock();
    }
}

- (void)drawingView:(WLDrawingView *)view didFinishWithImage:(UIImage *)image {
    if (self.doneBlock) {
        self.doneBlock(image);
    }
}

@end
