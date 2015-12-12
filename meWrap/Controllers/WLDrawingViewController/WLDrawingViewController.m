//
//  WLDrawingViewController.m
//  Wrap
//
//  Created by Sergey Maximenko on 8/17/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLDrawingViewController.h"
#import "WLButton.h"
#import "WLDrawingCanvas.h"
#import "WLDrawingSession.h"
#import "WLColorPicker.h"

@interface WLDrawingViewController () <WLDrawingSessionDelegate, WLColorPickerDelegate, WLDrawingViewControllerDelegate>

@property (strong, nonatomic) WLDrawingSession *session;
@property (weak, nonatomic) IBOutlet WLDrawingCanvas *canvas;
@property (weak, nonatomic) IBOutlet UIButton *undoButton;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet WLDrawingCanvas *brushCanvas;
@property (weak, nonatomic) IBOutlet UIView *colorsView;

@property (strong, nonatomic) NSArray* colors;

@property (strong, nonatomic) ImageBlock doneBlock;

@property (strong, nonatomic) Block cancelBlock;

@end

@implementation WLDrawingViewController

+ (instancetype)draw:(UIImage *)image finish:(ImageBlock)finish {
    UIViewController *presentingViewController = [UIWindow mainWindow].rootViewController;
    WLDrawingViewController *drawingViewController = [[WLDrawingViewController alloc] init];
    [drawingViewController setImage:image done:^(UIImage *image) {
        if (finish) finish(image);
        [presentingViewController dismissViewControllerAnimated:NO completion:nil];
    } cancel:^{
        [presentingViewController dismissViewControllerAnimated:NO completion:nil];
    }];
    [presentingViewController presentViewController:drawingViewController animated:NO completion:nil];
    return drawingViewController;
}

- (instancetype)init {
    return [self initWithNibName:@"WLDrawingViewController" bundle:nil];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.image) {
        [self.imageView addConstraint:[NSLayoutConstraint constraintWithItem:self.imageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.imageView attribute:NSLayoutAttributeHeight multiplier:self.image.size.width/self.image.size.height constant:0]];
        self.imageView.image = self.image;
    }
    [self.view layoutIfNeeded];
    
    self.session = self.canvas.session;
    self.session.delegate = self;
    self.session.interpolated = NO;
    self.session.brush = [WLDrawingBrush brushWithColor:[UIColor redColor] width:10];
    
    [self updateBrushView];
}

- (void)setImage:(UIImage *)image done:(ImageBlock)done cancel:(Block)cancel {
    [self setImage:image];
    self.delegate = self;
    self.doneBlock = done;
    self.cancelBlock = cancel;
}

- (IBAction)cancel:(id)sender {
    if ([self.delegate respondsToSelector:@selector(drawingViewControllerDidCancel:)]) {
        [self.delegate drawingViewControllerDidCancel:self];
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

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateBrushView];
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
    if ([self.delegate respondsToSelector:@selector(drawingViewController:didFinishWithImage:)]) {
        __weak typeof(self)weakSelf = self;
        
        UIImage *image = self.imageView.image;
        
        if (self.session.empty) {
            [self.delegate drawingViewControllerDidCancel:self];
            return;
        }
        
        CGSize size = CGSizeMake(image.size.width * image.scale, image.size.height * image.scale);
        image = [UIImage draw:size opaque:NO scale:1 drawing:^(CGSize size) {
            [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
            CGContextScaleCTM(UIGraphicsGetCurrentContext(), size.width / weakSelf.canvas.width, size.height / weakSelf.canvas.height);
            [weakSelf.session render];
        }];
        [self.delegate drawingViewController:self didFinishWithImage:image];
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

- (void)drawingViewControllerDidCancel:(WLDrawingViewController *)controller {
    if (self.cancelBlock) {
        self.cancelBlock();
    }
}

- (void)drawingViewController:(WLDrawingViewController *)controller didFinishWithImage:(UIImage *)image {
    if (self.doneBlock) {
        self.doneBlock(image);
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

@end
