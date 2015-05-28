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

- (void)addTransition:(void (^)(CATransition* transition))configuration duration:(NSTimeInterval)duration delegate:(id)delegate key:(NSString*)key {
	[self.layer removeAllAnimations];
	CATransition* transition = [CATransition animation];
	transition.delegate = delegate;
	transition.duration = duration;
	transition.fillMode = kCAFillModeBoth;
	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    configuration(transition);
    [self.layer addAnimation:transition forKey:key];
}

- (void)addTransition:(NSString*)type subtype:(NSString*)subtype duration:(NSTimeInterval)duration delegate:(id)delegate key:(NSString*)key {
	[self addTransition:^(CATransition *transition) {
		transition.type = type;
		if (subtype) {
			transition.subtype = subtype;
		}
	} duration:duration delegate:delegate key:key];
}

- (void)addTransition:(void (^)(CATransition* transition))configuration key:(NSString*)key {
	[self addTransition:configuration duration:QCDefaultAnimationDuration delegate:nil key:key];
}

- (void)fade {
    [self fadeWithDuration:QCDefaultAnimationDuration delegate:nil];
}

- (void)fadeWithDuration:(NSTimeInterval)duration delegate:(id)delegate {
	[self addTransition:kCATransitionFade subtype:nil duration:duration delegate:delegate key:QCFadeAnimationKey];
}

- (void)revealFrom:(NSString *)from {
    [self revealFrom:from withDuration:QCDefaultAnimationDuration delegate:nil];
}

- (void)revealFrom:(NSString *)from withDuration:(NSTimeInterval)duration delegate:(id)delegate {
	[self addTransition:kCATransitionReveal subtype:from duration:duration delegate:delegate key:QCRevealAnimationKey];
}

- (void)moveInFrom:(NSString *)from {
    [self moveInFrom:from withDuration:QCDefaultAnimationDuration delegate:nil];
}

- (void)moveInFrom:(NSString *)from withDuration:(NSTimeInterval)duration delegate:(id)delegate {
	[self addTransition:kCATransitionMoveIn subtype:from duration:duration delegate:delegate key:QCMoveInAnimationKey];
}

- (void)leftPush {
    [self leftPushWithDuration:QCDefaultAnimationDuration delegate:nil];
}

- (void)leftPushWithDuration:(NSTimeInterval)duration delegate:(id)delegate {
	[self addTransition:kCATransitionPush subtype:kCATransitionFromRight duration:duration delegate:delegate key:QCLeftPushAnimationKey];
}

- (void)rightPush {
    [self rightPushWithDuration:QCDefaultAnimationDuration delegate:nil];
}

- (void)rightPushWithDuration:(NSTimeInterval)duration delegate:(id)delegate {
	[self addTransition:kCATransitionPush subtype:kCATransitionFromLeft duration:duration delegate:delegate key:QCRightPushAnimationKey];
}

- (void)topPush {
    [self topPushWithDuration:QCDefaultAnimationDuration delegate:nil];
}

- (void)topPushWithDuration:(NSTimeInterval)duration delegate:(id)delegate {
	[self addTransition:kCATransitionPush subtype:kCATransitionFromBottom duration:duration delegate:delegate key:QCLeftPushAnimationKey];
}

- (void)bottomPush {
    [self bottomPushWithDuration:QCDefaultAnimationDuration delegate:nil];
}

- (void)bottomPushWithDuration:(NSTimeInterval)duration delegate:(id)delegate {
	[self addTransition:kCATransitionPush subtype:kCATransitionFromTop duration:duration delegate:delegate key:QCLeftPushAnimationKey];
}

- (void)setShadowOffset:(CGSize)offset blur:(CGFloat)blur {
    self.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.layer.shadowOffset = offset;
    self.layer.shadowOpacity = 1.0f;
    self.layer.shadowRadius = blur;
}

- (void)setShadow {
    [self setShadowOffset:CGSizeMake(0.0f, 0.0f) blur:1.0f];
}

- (void)setBorderShadowOffset:(CGSize)offset blur:(CGFloat)blur radius:(CGFloat)radius {
    [self setShadowOffset:offset blur:blur];
    self.layer.shadowPath = [[UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:radius] CGPath];
}

- (void)setBorderShadowOffset:(CGSize)offset blur:(CGFloat)blur {
    [self setBorderShadowOffset:offset blur:blur radius:0.0f];
}

- (void)setBorderShadow {
    [self setBorderShadowOffset:CGSizeMake(0.0f, 0.0f) blur:1.0f];
}

@end
