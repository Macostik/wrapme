//
//  WLSegmentedControl.m
//  WrapLive
//
//  Created by Yura Granchenko on 02/07/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLSegmentedControl.h"
#import "UIView+AnimationHelper.h"
#import "UIColor+CustomColors.h"

@interface WLSegmentedControl ()

@property (weak, nonatomic) IBOutlet UIView *sliceView;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *attributedViews;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leadingSliceViewConstraint;

@end

@implementation WLSegmentedControl

- (void)setSelectedControl:(UIControl *)control {
    [super setSelectedControl:control];
    [UIView performAnimated:YES animation:^{
        self.sliceView.transform = CGAffineTransformIdentity;
        self.leadingSliceViewConstraint.constant = control.x;
        [self.sliceView layoutIfNeeded];
        [self hightlightAttributedViewsForControl:control byColor:[UIColor whiteColor]];
        control.selected = NO;
    }];
}

// MARK: - UIPanHandlerOfSegmentedControl

CGFloat beganTouchPointX = .0;

- (IBAction)handlePanRecognizer:(UIPanGestureRecognizer *)recognizer {
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            beganTouchPointX = [recognizer locationInView:self].x;
            [UIView performAnimated:YES animation:^{
                self.sliceView.transform = CGAffineTransformMakeScale(0.8, 0.8);
            }];
            break;
        }
        case UIGestureRecognizerStateChanged: {
           CGPoint changePoint = [recognizer translationInView:self];
            [UIView performAnimated:YES animation:^{
                [self hightlightAttributedViewsForControl:nil byColor:[UIColor WL_grayLighter]];
                self.leadingSliceViewConstraint.constant = beganTouchPointX + changePoint.x - self.sliceView.width/2;
                [self.sliceView layoutIfNeeded];
            }];
            break;
        }
        case UIGestureRecognizerStateEnded:
        UIGestureRecognizerStateCancelled:
        UIGestureRecognizerStateFailed: {
            NSInteger selectedSegment = [self indexSegmentByPositionPoint:[recognizer translationInView:self]];
            UIControl *control = [self controlForSegment:selectedSegment];
            [self setSelectedControl:control];
            [control sendActionsForControlEvents:UIControlEventTouchUpInside];
            break;
        }
        default:
            break;
    }
}

- (NSUInteger)indexSegmentByPositionPoint:(CGPoint)point {
    return MIN(2, ABS((beganTouchPointX + point.x)/(self.width/self.controls.count)));
}

- (void)hightlightAttributedViewsForControl:(UIControl *)control byColor:(UIColor *)color {
    for (UIView *attributedView in self.attributedViews) {
         [attributedView.subviews setValue:attributedView.superview.x == control.x ?
                                            color : [UIColor WL_grayLighter] forKey:@"textColor"];
    }
}

@end
