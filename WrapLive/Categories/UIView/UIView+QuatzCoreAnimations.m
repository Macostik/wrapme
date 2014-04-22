//
//  UIView+QuatzCoreAnimations.m
//  Riot
//
//  Created by Sergey Maximenko on 24.01.13.
//
//

#import "UIView+QuatzCoreAnimations.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIView (QuatzCoreAnimations)

- (void)fade
{
    [self fadeWithDuration:kDefaultAnimationDuration delegate:nil];
}

- (void)fadeWithDuration:(NSTimeInterval)duration delegate:(id)delegate
{
    CATransition* fadeTransition = [CATransition animation];
    
    fadeTransition.duration = duration;
    fadeTransition.type = kCATransitionFade;
    fadeTransition.delegate = delegate;
    
    [self.layer addAnimation:fadeTransition forKey:kFadeAnimationKey];
}

- (void)revealFrom:(NSString *)from
{
    [self revealFrom:from withDuration:kDefaultAnimationDuration delegate:nil];
}

- (void)revealFrom:(NSString *)from withDuration:(NSTimeInterval)duration delegate:(id)delegate
{
    self.layer.opaque = YES;
    
    CATransition* fadeTransition = [CATransition animation];
    
    fadeTransition.duration = duration;
    fadeTransition.type = kCATransitionReveal;
    if (from)
    {
        fadeTransition.subtype = from;
    }
    fadeTransition.delegate = delegate;
    
    [self.layer addAnimation:fadeTransition forKey:kRevealAnimationKey];
}

- (void)moveInFrom:(NSString *)from
{
    [self moveInFrom:from withDuration:kDefaultAnimationDuration delegate:nil];
}

- (void)moveInFrom:(NSString *)from withDuration:(NSTimeInterval)duration delegate:(id)delegate
{
    self.layer.opaque = YES;
    
    CATransition* fadeTransition = [CATransition animation];
    
    fadeTransition.duration = duration;
    fadeTransition.type = kCATransitionMoveIn;
    if (from)
    {
        fadeTransition.subtype = from;
    }
    fadeTransition.delegate = delegate;
    
    [self.layer addAnimation:fadeTransition forKey:kMoveInAnimationKey];
}

- (void)leftPush
{
    [self leftPushWithDuration:kDefaultAnimationDuration delegate:nil];
}

- (void)leftPushWithDuration:(NSTimeInterval)duration delegate:(id)delegate
{
    [self.layer removeAllAnimations];
    
    CATransition* transition = [CATransition animation];
    transition.duration = duration;
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromRight;
    transition.delegate = delegate;
    transition.fillMode = kCAFillModeBoth;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    [self.layer addAnimation:transition forKey:kLeftPushAnimationKey];
}

- (void)rightPush
{
    [self rightPushWithDuration:kDefaultAnimationDuration delegate:nil];
}

- (void)rightPushWithDuration:(NSTimeInterval)duration delegate:(id)delegate
{
    [self.layer removeAllAnimations];
    
    CATransition* transition = [CATransition animation];
    transition.duration = duration;
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromLeft;
    transition.delegate = delegate;
    transition.fillMode = kCAFillModeBoth;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    [self.layer addAnimation:transition forKey:kLeftPushAnimationKey];
}

- (void)topPush
{
    [self topPushWithDuration:kDefaultAnimationDuration delegate:nil];
}

- (void)topPushWithDuration:(NSTimeInterval)duration delegate:(id)delegate
{
    CATransition* transition = [CATransition animation];
    transition.duration = duration;
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromBottom;
    transition.delegate = delegate;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    [self.layer addAnimation:transition forKey:kLeftPushAnimationKey];
}

- (void)bottomPush
{
    [self bottomPushWithDuration:kDefaultAnimationDuration delegate:nil];
}

- (void)bottomPushWithDuration:(NSTimeInterval)duration delegate:(id)delegate
{
    CATransition* transition = [CATransition animation];
    transition.duration = duration;
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromTop;
    transition.delegate = delegate;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    [self.layer addAnimation:transition forKey:kLeftPushAnimationKey];
}

- (void)setShadowOffset:(CGSize)offset blur:(CGFloat)blur
{
    self.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.layer.shadowOffset = offset;
    self.layer.shadowOpacity = 1.0f;
    self.layer.shadowRadius = blur;
}

- (void)setShadow
{
    [self setShadowOffset:CGSizeMake(0.0f, 0.0f) blur:1.0f];
}

- (void)setBorderShadowOffset:(CGSize)offset blur:(CGFloat)blur radius:(CGFloat)radius
{
    [self setShadowOffset:offset blur:blur];
    
    self.layer.shadowPath = [[UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:radius] CGPath];
}

- (void)setBorderShadowOffset:(CGSize)offset blur:(CGFloat)blur
{
    [self setBorderShadowOffset:offset blur:blur radius:0.0f];
}

- (void)setBorderShadow
{
    [self setBorderShadowOffset:CGSizeMake(0.0f, 0.0f) blur:1.0f];
}

@end
