//
//  UIView+QuatzCoreAnimations.h
//  Riot
//
//  Created by Ravenpod on 24.01.13.
//
//

#import <UIKit/UIKit.h>

static NSTimeInterval QCDefaultAnimationDuration = 0.33f;
static NSString* QCFadeAnimationKey = @"Fade";
static NSString* QCLeftPushAnimationKey = @"LeftPush";
static NSString* QCRightPushAnimationKey = @"RightPush";
static NSString* QCRevealAnimationKey = @"Reveal";
static NSString* QCMoveInAnimationKey = @"MoveIn";

@interface UIView (QuatzCoreAnimations)

- (void)fade;

- (void)fadeWithDuration:(NSTimeInterval)duration delegate:(id)delegate;

- (void)revealFrom:(NSString*)from;

- (void)revealFrom:(NSString*)from withDuration:(NSTimeInterval)duration delegate:(id)delegate;

- (void)moveInFrom:(NSString*)from;

- (void)moveInFrom:(NSString*)from withDuration:(NSTimeInterval)duration delegate:(id)delegate;

- (void)leftPush;

- (void)leftPushWithDuration:(NSTimeInterval)duration delegate:(id)delegate;

- (void)rightPush;

- (void)rightPushWithDuration:(NSTimeInterval)duration delegate:(id)delegate;

- (void)topPush;

- (void)topPushWithDuration:(NSTimeInterval)duration delegate:(id)delegate;

- (void)bottomPush;

- (void)bottomPushWithDuration:(NSTimeInterval)duration delegate:(id)delegate;

- (void)setShadowOffset:(CGSize)offset blur:(CGFloat)blur;

- (void)setShadow;

- (void)setBorderShadowOffset:(CGSize)offset blur:(CGFloat)blur radius:(CGFloat)radius;

- (void)setBorderShadowOffset:(CGSize)offset blur:(CGFloat)blur;

- (void)setBorderShadow;

@end
