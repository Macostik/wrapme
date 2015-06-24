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
@property (weak, nonatomic) IBOutlet UIImageView *brushImageView;
@property (weak, nonatomic) IBOutlet UIView *colorsView;

@property (strong, nonatomic) NSArray* colors;

@end

@implementation WLDrawingView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.session = [[WLDrawingSession alloc] init];
    self.session.delegate = self;
    self.session.brush = [WLDrawingBrush brushWithColor:[UIColor redColor] width:24];
}

- (void)setImage:(UIImage *)image {
    self.imageView.image = image;
    self.imageView.userInteractionEnabled = YES;
    CGRect drawingRect = CGRectThatFitsSize(self.imageView.size, self.imageView.image.size);
    WLDrawingCanvas* canvas = [[WLDrawingCanvas alloc] initWithFrame:drawingRect];
    self.canvas = canvas;
    canvas.opaque = NO;
    canvas.backgroundColor = [UIColor clearColor];
    canvas.session = self.session;
    [self.imageView addSubview:canvas];
    [self updateBrushView];
    
    [self.imageView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:canvas action:@selector(panning:)]];
    [canvas addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:canvas action:@selector(panning:)]];
}

- (IBAction)cancel:(id)sender {
    if ([self.delegate respondsToSelector:@selector(drawingViewDidCancel:)]) {
        [self.delegate drawingViewDidCancel:self];
    }
}

- (IBAction)decreaseBrush:(id)sender {
    CGFloat size = self.session.brush.width;
    if (size > 3) {
        self.session.brush.width = size - 3;
        [self updateBrushView];
    }
}

- (IBAction)increaseBrush:(id)sender {
    CGFloat size = self.session.brush.width;
    if (size < 51) {
        self.session.brush.width = size + 3;
        [self updateBrushView];
    }
}

- (void)updateBrushView {
    CGFloat size = self.session.brush.width;
    __weak typeof(self)weakSelf = self;
    self.brushImageView.image = [UIImage draw:CGSizeMake(size, size) opaque:NO scale:1 drawing:^(CGSize drawSize) {
        WLDrawingSession *session = [[WLDrawingSession alloc] init];
        session.brush = weakSelf.session.brush;
        [session beginDrawing];
        [session addPoint:CGPointMake(size/2.0f, size/2.0f)];
//        [session addPoint:CGPointMake(size/2.0f, size/2.0f)];
        [session endDrawing];
        [session render:YES];
    }];
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
        CGSize size = image.size;
        image = [UIImage draw:size opaque:NO scale:1 drawing:^(CGSize size) {
            [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
            CGContextScaleCTM(UIGraphicsGetCurrentContext(), size.width / weakSelf.canvas.width, size.height / weakSelf.canvas.height);
            [weakSelf.session render:YES];
        }];
        [self.delegate drawingView:self didFinishWithImage:image];
    }
}

// MARK: - WLDrawingSessionDelegate

- (void)drawingSession:(WLDrawingSession *)session didEndDrawing:(WLDrawingLine *)line {
    self.undoButton.hidden = session.empty;
}

// MARK: - WLColorPickerDelegate

- (void)colorPicker:(WLColorPicker *)picker pickedColor:(UIColor *)color {
    self.session.brush.color = color;
    [self updateBrushView];
}

@end
