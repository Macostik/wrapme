//
//  WLDrawingView.m
//  wrapLive
//
//  Created by Sergey Maximenko on 6/23/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLDrawingView.h"
#import "RMPaint.h"
#import "WLButton.h"

@interface WLDrawingView () <RMGestureCanvasViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) NSMutableArray *session;
@property (strong, nonatomic) NSMutableArray *steps;
@property (weak, nonatomic) RMCanvasView *canvas;
@property (weak, nonatomic) IBOutlet UIButton *undoButton;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *brushImageView;
@property (weak, nonatomic) IBOutlet UICollectionView *colorsView;

@end

@implementation WLDrawingView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.session = [NSMutableArray array];
    [self.colorsView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
}

- (void)setImage:(UIImage *)image {
    self.imageView.image = image;
    self.imageView.userInteractionEnabled = YES;
    [self setCanvasWithBrushColor:[UIColor WL_orange] size:64];
    [self.colorsView reloadData];
}

- (void)setCanvasWithBrushColor:(UIColor*)color size:(CGFloat)size {
    if (self.canvas) {
        [self.canvas removeFromSuperview];
    }
    __weak typeof(self)weakSelf = self;
    run_after_asap(^{
        CGRect drawingRect = CGRectThatFitsSize(weakSelf.imageView.size, weakSelf.imageView.image.size);
        RMCanvasView* canvas = [[RMGestureCanvasView alloc] initWithFrame:drawingRect];
        weakSelf.canvas = canvas;
        canvas.opaque = NO;
        canvas.backgroundColor = [UIColor clearColor];
        canvas.delegate = weakSelf;
        canvas.brushColor = color;
        canvas.delegate = weakSelf;
        [weakSelf setBrushWithSize:size];
        [weakSelf.imageView addSubview:canvas];
        
        if (weakSelf.session.nonempty) {
            NSMutableArray *allSteps = [NSMutableArray array];
            for (NSArray *steps in weakSelf.session) {
                [allSteps addObjectsFromArray:steps];
            }
            [weakSelf.canvas renderSteps:allSteps];
        }
    });
}

- (void)setBrushWithSize:(CGFloat)size {
    __weak typeof(self)weakSelf = self;
    UIImage *brush = [UIImage draw:CGSizeMake(size, size) opaque:NO scale:1 drawing:^(CGSize drawSize) {
        UIColor *color = weakSelf.canvas.brushColor;
        NSArray *colors = @[(id)color.CGColor,(id)[color colorWithAlphaComponent:0].CGColor];
        CGGradientRef gradient = CGGradientCreateWithColors(NULL, (__bridge CFArrayRef)(colors), NULL);
        CGFloat radius = size/2.0f;
        CGPoint center = CGPointMake(radius, radius);
        CGContextDrawRadialGradient(UIGraphicsGetCurrentContext(), gradient, center, radius/2, center, radius, kCGGradientDrawsBeforeStartLocation);
        CGGradientRelease(gradient);
    }];
    self.canvas.brush = brush;
    self.brushImageView.image = brush;
}

- (IBAction)cancel:(id)sender {
    if ([self.delegate respondsToSelector:@selector(drawingViewDidCancel:)]) {
        [self.delegate drawingViewDidCancel:self];
    }
}

- (IBAction)decreaseBrush:(id)sender {
    CGFloat size = self.canvas.brush.size.width;
    if (size > 10) {
        [self setCanvasWithBrushColor:self.canvas.brushColor size:size - 3];
    }
}

- (IBAction)increaseBrush:(id)sender {
    CGFloat size = self.canvas.brush.size.width;
    if (size < 100) {
        [self setCanvasWithBrushColor:self.canvas.brushColor size:size + 3];
    }
}

- (IBAction)undo:(id)sender {
    [self.session removeLastObject];
    [self.canvas erase];
    NSMutableArray *allSteps = [NSMutableArray array];
    for (NSArray *steps in self.session) {
        [allSteps addObjectsFromArray:steps];
    }
    [self.canvas renderSteps:allSteps];
    
    self.undoButton.hidden = !self.session.nonempty;
}

- (IBAction)finish:(WLButton *)sender {
    if ([self.delegate respondsToSelector:@selector(drawingView:didFinishWithImage:)]) {
        
        __weak typeof(self)weakSelf = self;
        
        UIImage *image = self.imageView.image;
        CGSize size = image.size;
        image = [UIImage draw:size opaque:NO scale:1 drawing:^(CGSize size) {
            [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
            [weakSelf.canvas renderSnapshotWithSize:size];
        }];
        [self.delegate drawingView:self didFinishWithImage:image];
        
        
//        sender.loading = YES;
//        run_getting_object(^id{
//            UIImage *image = weakSelf.imageView.image;
//            CGSize size = image.size;
//            return [UIImage draw:size opaque:NO scale:1 drawing:^(CGSize size) {
//                [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
//                [weakSelf.canvas renderSnapshotWithSize:size];
//            }];
//        }, ^(UIImage *image) {
//            sender.loading = NO;
//            [weakSelf.delegate drawingView:weakSelf didFinishWithImage:image];
//        });
    }
}

// MARK: - RMGestureCanvasViewDelegate

- (void)canvasViewDidBeginPaintingInteraction:(RMCanvasView *)canvasView {
    self.steps = [NSMutableArray array];
}

- (void)canvasView:(RMCanvasView *)canvasView painted:(RMPaintStep *)step {
    if (self.steps && step) {
        [self.steps addObject:step];
    }
}

- (void)canvasViewDidEndPaintingInteraction:(RMCanvasView *)canvasView {
    if (self.steps.count > 0) {
        [self.session addObject:self.steps];
        self.undoButton.hidden = NO;
    }
    self.steps = nil;
}

// MARK: - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 100;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor colorWithRed:indexPath.item / 100.0f green:1 - indexPath.item / 100.0f blue:indexPath.item / 100.0f alpha:1];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(collectionView.width/100.0f, collectionView.height);
}

- (IBAction)colorPickerSelection:(UIPanGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateChanged) {
        CGPoint location = [sender locationInView:self.colorsView];
        for (UICollectionViewCell *cell in [self.colorsView visibleCells]) {
            if (CGRectContainsPoint(cell.frame, location)) {
                self.canvas.brushColor = cell.backgroundColor;
                [self setBrushWithSize:self.canvas.brush.size.width];
                break;
            }
        }
    }
}

@end
