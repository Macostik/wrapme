//
//  WLViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 19.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWelcomeViewController.h"
#import "WLSession.h"
#import "WLAPIManager.h"
#import "WLNavigation.h"
#import "WLAuthorization.h"
#import "WLSignUpViewController.h"
#import "NSString+Additions.h"
#import "WLUser.h"
#import "WLHomeViewController.h"
#import "UIFont+CustomFonts.h"
#import "UIColor+CustomColors.h"
#import "UIView+Shorthand.h"
#import "WLLoadingView.h"
#import "WLAuthorizationRequest.h"
#import "UIView+GestureRecognizing.h"
#import "WLTermsAndConditionsKeys.h"

typedef enum : NSUInteger {
    WLFlipDirectionRight,
    WLFlipDirectionLeft,
} WLFlipDirection;

@interface WLWelcomeViewController () <UIGestureRecognizerDelegate>

@property (weak, nonatomic) WLLoadingView *splash;
@property (weak, nonatomic) IBOutlet UIButton *licenseButton;
@property (weak, nonatomic) IBOutlet UIView *transparentView;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundView;
@property (strong, nonatomic) IBOutlet UIView *placeholderView;
@property (weak, nonatomic) IBOutlet UITextView *termsAndConditionsTextView;

@end

@implementation WLWelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.placeholderView.layer.cornerRadius = 5.0f;
    self.placeholderView.layer.masksToBounds = YES;
    
    WLLoadingView* splash = [WLLoadingView splash];
    splash.frame = self.view.bounds;
    [self.view addSubview:splash];
    self.splash = splash;
	
    WLAuthorization* authorization = [WLAuthorization currentAuthorization];
	if ([authorization canAuthorize]) {
		__weak typeof(self)weakSelf = self;
        [authorization signIn:^(WLUser *user) {
            [weakSelf presentHomeViewController];
        } failure:^(NSError *error) {
            if ([error isNetworkError]) {
				[weakSelf presentHomeViewController];
			} else {
				[weakSelf unlockUI];
			}
        }];
	} else {
		[self unlockUI];
	}
    
    [self wrapIntoAttributedString];
    
    __weak __typeof(self)weakSelf = self;
    [self.placeholderView addSwipeGestureRecognizingDelegate:self
                                                   direction:UISwipeGestureRecognizerDirectionLeft | UISwipeGestureRecognizerDirectionRight
                                                       block:^(UIGestureRecognizer *recognizer) {
                                                           [weakSelf flipAnimationView:WLFlipDirectionRight];
                                                           weakSelf.termsAndConditionsTextView.scrollEnabled = YES;
                                                       }];
}

- (void)unlockUI {
	[self underlineLicenseButton];
	__weak typeof(self)weakSelf = self;
	[UIView animateWithDuration:0.25f animations:^{
		weakSelf.splash.alpha = 0.0f;
	} completion:^(BOOL finished) {
        [weakSelf.splash hide];
    }];
    self.splash.animating = NO;
    [self animateBackgroundView];
}

- (void)animateBackgroundView {
    __weak typeof(self)weakSelf = self;
    
    NSTimeInterval duration = 30;
    
    __block void (^animationDown) (void) = nil;
    __block void (^animationUp) (void) = nil;
    
    animationDown = ^ {
        [UIView animateWithDuration:duration delay:0.0f options:UIViewAnimationOptionCurveLinear animations:^{
            weakSelf.backgroundView.transform = CGAffineTransformMakeTranslation(0, -(weakSelf.backgroundView.bounds.size.height - weakSelf.view.bounds.size.height));
        } completion:^(BOOL finished) {
            animationUp();
        }];
    };
    
    animationUp = ^ {
        [UIView animateWithDuration:duration delay:0.0f options:UIViewAnimationOptionCurveLinear animations:^{
            weakSelf.backgroundView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            animationDown();
        }];
    };
    
    animationDown();
}

- (void)underlineLicenseButton {
	NSMutableAttributedString *titleString = [[NSMutableAttributedString alloc] initWithString:@"Terms and Conditions"];
	NSDictionary * attributes = @{NSUnderlineStyleAttributeName : [NSNumber numberWithInteger:NSUnderlineStyleSingle],
								  NSFontAttributeName : [UIFont lightFontOfSize:15],
								  NSForegroundColorAttributeName : [UIColor WL_orangeColor]};
	[titleString addAttributes:attributes range:NSMakeRange(0, [titleString length])];
	[self.licenseButton setAttributedTitle: titleString forState:UIControlStateNormal];
}

- (void)presentHomeViewController {
    if ([WLUser currentUser].name.nonempty) {
        [WLHomeViewController instantiateAndMakeRootViewControllerAnimated:NO];
    } else {
        [self continueSignUp];
    }
}

- (void)continueSignUp {
	[WLSignUpViewController instantiate:^(WLSignUpViewController *controller) {
		controller.registrationNotCompleted = YES;
	} makeRootViewControllerAnimated:WLFlipDirectionRight];
}

- (IBAction)termsAndConditions:(id)sender {
    [self flipAnimationView:WLFlipDirectionLeft];
    self.termsAndConditionsTextView.scrollEnabled = YES;
}

- (void)flipAnimationView:(WLFlipDirection)direction {
    self.termsAndConditionsTextView.scrollEnabled = NO;
    UIView *fromView = direction == WLFlipDirectionRight ? self.placeholderView : self.transparentView;
    UIView *toView = direction == WLFlipDirectionRight ? self.transparentView : self.placeholderView;
    
    float factor = direction == WLFlipDirectionRight ? 1.0 : -1.0;
    toView.layer.transform = [self yRotation:factor * -M_PI_2];
    toView.hidden = NO;
    
    
    [UIView animateKeyframesWithDuration:1.0
                                   delay:0.0
                                 options:0
                              animations:^{
                                  [UIView addKeyframeWithRelativeStartTime:0.0
                                                          relativeDuration:0.5
                                                                animations:^{
                                                                    fromView.layer.transform = [self yRotation:factor * M_PI_2];
                                                                }];
                                  [UIView addKeyframeWithRelativeStartTime:0.5
                                                          relativeDuration:0.5
                                                                animations:^{
                                                                    toView.layer.transform = CATransform3DIdentity;
                                                                }];
                              } completion:NULL];
}

- (CATransform3D)yRotation:(CGFloat)angle {
    return  CATransform3DMakeRotation(angle, 0.0, 1.0, 0.0);
}

- (void)wrapIntoAttributedString {
    NSURL *url  = [NSURL fileURLWithPath:[[NSBundle mainBundle]pathForResource:@"Wraplive_TermsAndConditions" ofType:@"rtf"]];
    if (url != nil) {
        NSData *rtfData = [NSData dataWithContentsOfURL:url];
        if (rtfData != nil) {
            NSAttributedString *attrString = [[NSAttributedString alloc]
                                              initWithData:rtfData options:nil documentAttributes:nil error:nil];
            if ([attrString string].nonempty) {
                NSDictionary * textAttributes = @{NSFontAttributeName : [UIFont lightFontOfSize:15],
                                                  NSForegroundColorAttributeName : [UIColor blackColor]};
                NSMutableParagraphStyle *paragrapStyle = [NSMutableParagraphStyle new];
                paragrapStyle.alignment = NSTextAlignmentCenter;
                NSDictionary * titleAttributes = @{NSFontAttributeName : [UIFont lightFontOfSize:25],
                                                   NSForegroundColorAttributeName : [UIColor WL_orangeColor],
                                                   NSParagraphStyleAttributeName : paragrapStyle};
                
                NSMutableAttributedString *attrText = attrString.mutableCopy;
                [attrText addAttributes:textAttributes range:NSMakeRange(0 , [attrString length])];
                
                [titleKeyArray() all:^(id item) {
                    NSRange range = [[attrText string] rangeOfString:item];
                    if (range.location != NSNotFound) {
                        [attrText setAttributes:titleAttributes range:range];
                    }
                }];
                
                self.termsAndConditionsTextView.attributedText = attrText;
                self.termsAndConditionsTextView.editable = NO;
                self.termsAndConditionsTextView.dataDetectorTypes = UIDataDetectorTypeAll;
            }
        }
    }
}

#pragma mark -UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end
