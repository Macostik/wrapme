//
//  WLPresentingImageView.m
//  WrapLive
//
//  Created by Yura Granchenko on 26/05/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLPresentingImageView.h"
#import "WLNavigationHelper.h"
#import "WLCandyCell.h"

@interface WLPresentingImageView () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet WLImageView *imageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *aspectRatioConstraint;

@end

@implementation WLPresentingImageView

+ (instancetype)sharedPresenting {
    return [WLPresentingImageView loadFromNib];
}

+ (instancetype)presentingCandy:(WLCandy *)candy completion:(WLBooleanBlock)completion {
    return [[WLPresentingImageView sharedPresenting] presentingCandy:candy completion:completion];
}

- (instancetype)presentingCandy:(WLCandy *)candy completion:(WLBooleanBlock)completion {
    UIView *parentView = [[UINavigationController topViewController] view];
    self.backgroundColor = [UIColor clearColor];
    self.frame = parentView.frame;

    CGRect convertRect = CGRectZero;
    if ([self.delegate respondsToSelector:@selector(presentingImageView:frameForCandy:)]) {
        convertRect = [self.delegate presentingImageView:self frameForCandy:candy];
    }
    
    run_after(.1,  ^{
      self.imageView.frame = convertRect;
         [parentView addSubview:self];
    });
    
    [self performAnimationCandy:candy completion:completion];
    return self;
}

- (void)dismissCandy:(WLCandy *)candy {
    self.backgroundColor = [UIColor clearColor];
    CGRect convertRect = CGRectZero;
    if ([self.delegate respondsToSelector:@selector(presentingImageView:frameForCandy:)]) {
        convertRect = [self.delegate presentingImageView:self frameForCandy:candy];
    }
    run_after(.1, ^{
        [UIView animateWithDuration:0.25
                              delay:.0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.imageView.frame = convertRect;
                         } completion:^(BOOL finished) {
                             [self removeFromSuperview];
                         }];
    });
}

- (void)performAnimationCandy:(WLCandy *)candy completion:(WLBooleanBlock)completion {
    [self.imageView setUrl:candy.picture.large];
    run_after(.1, ^{
        [UIView animateWithDuration:0.25
                              delay:.0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.imageView.hidden = NO;
                             [self calculateScaleValues];
                             [self.imageView layoutIfNeeded];
                             self.backgroundColor = [UIColor blackColor];
                         } completion:completion];
    });
}

- (void)setImageUrl:(NSString *)url {
     [self.imageView setUrl:url];
}

- (void)calculateScaleValues {
    UIImage *image = self.imageView.image;
    if (image) {
        NSLayoutConstraint *constraint = self.aspectRatioConstraint;
        constraint = [NSLayoutConstraint constraintWithItem:constraint.firstItem
                                                  attribute:constraint.firstAttribute
                                                  relatedBy:constraint.relation
                                                     toItem:constraint.secondItem
                                                  attribute:constraint.secondAttribute
                                                 multiplier:image.size.width/image.size.height constant:0];
        [self.imageView removeConstraint:self.aspectRatioConstraint];
        [self.imageView addConstraint:constraint];
        self.aspectRatioConstraint = constraint;
    }
}



@end
