//
//  UIView+QuatzCoreAnimations.h
//  Riot
//
//  Created by Sergey Maximenko on 24.01.13.
//
//

#import <UIKit/UIKit.h>

#define kDefaultAnimationDuration 0.4f
#define kFadeAnimationKey @"Fade"
#define kLeftPushAnimationKey @"LeftPush"
#define kRightPushAnimationKey @"RightPush"
#define kRevealAnimationKey @"Reveal"
#define kMoveInAnimationKey @"MoveIn"

@interface UIView (QuatzCoreAnimations)

- (void)fade;
- (void)fadeWithDuration:(NSTimeInterval)duration delegate:(id)delegate;

- (void)revealFrom:(NSString*)from;
- (void)revealFrom:(NSString*)from withDuration:(NSTimeInterval)duration delegate:(id)delegate;

- (void)moveInFrom:(NSString*)from;;
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
