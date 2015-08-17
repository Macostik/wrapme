//
//  WLSegmentedControl.m
//  moji
//
//  Created by Yura Granchenko on 02/07/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLSegmentedControl.h"
#import "UIView+AnimationHelper.h"

@interface WLSegmentedControl ()

@property (weak, nonatomic) IBOutlet UIView *sliceView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leadingSliceViewConstraint;

@end

@implementation WLSegmentedControl

- (void)awakeFromNib {
    [super awakeFromNib];
    [self addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)setSelectedSegment:(NSInteger)selectedSegment {
    [super setSelectedSegment:selectedSegment];
    [self updateSliceViewWithControl:[self controlForSegment:selectedSegment] animated:YES];
}

- (void)segmentChanged:(WLSegmentedControl*)sender {
    [self updateSliceViewWithControl:[sender controlForSegment:sender.selectedSegment] animated:YES];
}

- (void)updateSliceViewWithControl:(UIControl *)control animated:(BOOL)animated {
    __weak typeof(self)weakSelf = self;
    [UIView performAnimated:animated animation:^{
        weakSelf.sliceView.transform = CGAffineTransformIdentity;
        weakSelf.leadingSliceViewConstraint.constant = control.x;
        [weakSelf.sliceView layoutIfNeeded];
    }];
}

// MARK: - UIPanHandlerOfSegmentedControl

- (IBAction)handlePanRecognizer:(UIPanGestureRecognizer *)recognizer {
    CGFloat location = [recognizer locationInView:self].x;
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            [UIView performAnimated:YES animation:^{
                self.sliceView.transform = CGAffineTransformMakeScale(0.8, 0.8);
                self.leadingSliceViewConstraint.constant = location - self.sliceView.width/2;
                [self.sliceView layoutIfNeeded];
            }];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            self.leadingSliceViewConstraint.constant = location - self.sliceView.width/2;
            [self.sliceView setNeedsLayout];
            break;
        }
        case UIGestureRecognizerStateEnded:
        UIGestureRecognizerStateCancelled:
        UIGestureRecognizerStateFailed: {
            NSInteger selectedSegment = MIN(2, ABS(location/(self.width/self.controls.count)));
            if (self.selectedSegment == selectedSegment) {
                [self updateSliceViewWithControl:[self controlForSegment:selectedSegment] animated:YES];
            } else {
                self.selectedSegment = selectedSegment;
                [self sendActionsForControlEvents:UIControlEventValueChanged];
            }
            break;
        }
        default:
            break;
    }
}

@end
