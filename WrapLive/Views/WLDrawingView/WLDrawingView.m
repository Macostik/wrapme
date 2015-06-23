//
//  WLDrawingView.m
//  wrapLive
//
//  Created by Sergey Maximenko on 6/23/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLDrawingView.h"
#import "RMPaint.h"

@interface WLDrawingView () <RMCanvasViewDelegate>

@property (strong, nonatomic) RMPaintSession *session;
@property (weak, nonatomic) IBOutlet RMCanvasView *paintingView;
@property (weak, nonatomic) IBOutlet UIButton *undoButton;

@end

@implementation WLDrawingView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.session = [[RMPaintSession alloc] init];
    self.paintingView.brushColor = [UIColor WL_orange];
    self.paintingView.delegate = self;
    self.paintingView.brush = [UIImage imageNamed:@"brush.png"];
    [self.session paintInCanvas:self.paintingView];
}

- (IBAction)cancel:(id)sender {
    if ([self.delegate respondsToSelector:@selector(drawingViewDidCancel:)]) {
        [self.delegate drawingViewDidCancel:self];
    }
}

- (IBAction)undo:(id)sender {
    NSArray *steps = [[self.session steps] copy];
    [self.session clear];
    [self.paintingView erase];
    for (RMPaintStep *step in steps) {
        if (step != [steps lastObject]) {
            [self.session addStep:step];
        }
    }
    self.paintingView.delegate = nil;
    [self.session paintInCanvas:self.paintingView];
    self.paintingView.delegate = self;
}

- (IBAction)finish:(id)sender {
    if ([self.delegate respondsToSelector:@selector(drawingViewDidFinish:)]) {
        [self.delegate drawingViewDidFinish:self];
    }
}

// MARK: - RMCanvasViewDelegate

- (void)canvasView:(RMCanvasView *)canvasView painted:(RMPaintStep *)step {
    [self.session addStep:step];
}

@end
