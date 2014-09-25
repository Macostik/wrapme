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
#import "WLInternetConnectionBroadcaster.h"

typedef enum : NSUInteger {
    WLFlipDirectionRight,
    WLFlipDirectionLeft,
} WLFlipDirection;

#define WLTermsAndContitionsURL @"https://www.wraplive.com/welcome/terms_and_conditions"

@interface WLWelcomeViewController () <UIGestureRecognizerDelegate>

@property (weak, nonatomic) WLLoadingView *splash;
@property (weak, nonatomic) IBOutlet UIButton *licenseButton;
@property (weak, nonatomic) IBOutlet UIView *transparentView;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundView;
@property (strong, nonatomic) UIWebView *termsAndConditionsWebView;
@property (weak, nonatomic) IBOutlet UIWebView *web;

@end

@implementation WLWelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    
    self.termsAndConditionsWebView = [UIWebView new];
    self.termsAndConditionsWebView.layer.cornerRadius = 5.0f;
    self.termsAndConditionsWebView.clipsToBounds = YES;
    self.termsAndConditionsWebView.scrollView.showsHorizontalScrollIndicator = NO;
    self.termsAndConditionsWebView.backgroundColor = [[UIColor alloc] initWithWhite:1.0 alpha:0.8];
    self.termsAndConditionsWebView.frame = self.transparentView.frame;
    self.termsAndConditionsWebView.dataDetectorTypes = UIDataDetectorTypeAll;
    self.termsAndConditionsWebView.hidden = YES;
    [self.transparentView.superview addSubview:self.termsAndConditionsWebView];
    
    [[WLInternetConnectionBroadcaster broadcaster] addReceiver:self];
    
    NSURL *url = nil;
    if (![WLInternetConnectionBroadcaster broadcaster].reachable)  {
        url  = [NSURL fileURLWithPath:[[NSBundle mainBundle]pathForResource:@"Wraplive_TermsAndConditions.html" ofType:nil]];
    } else  {
        url = [NSURL URLWithString:WLTermsAndContitionsURL];
        self.termsAndConditionsWebView.scrollView.contentInset = UIEdgeInsetsMake(0, -17, 0, -17);
    }
   
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.termsAndConditionsWebView loadRequest:request];
    [self.web loadRequest:request];
    
    __weak __typeof(self)weakSelf = self;
    [self.termsAndConditionsWebView addTapGestureRecognizingDelegate:self block:^(UIGestureRecognizer *recognizer) {
        [weakSelf flipAnimationView:WLFlipDirectionRight];
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
}

- (void)flipAnimationView:(WLFlipDirection)direction {
    UIView *fromView = direction == WLFlipDirectionRight ? self.termsAndConditionsWebView : self.transparentView;
    UIView *toView = direction == WLFlipDirectionRight ? self.transparentView : self.termsAndConditionsWebView;
    
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
                                                                    toView.layer.transform = [self yRotation:.0f];
                                                                }];
                              } completion:NULL];
    
}

- (CATransform3D)yRotation:(CGFloat)angle {
    return  CATransform3DMakeRotation(angle, 0.0, 1.0, 0.0);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark WLInternetConnectionBroadcaster

- (void)broadcaster:(WLInternetConnectionBroadcaster *)broadcaster internetConnectionReachable:(NSNumber *)reachable {
    if (reachable) {
        [self.termsAndConditionsWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:WLTermsAndContitionsURL]]];
        self.termsAndConditionsWebView.scrollView.contentInset = UIEdgeInsetsMake(0, -17, 0, -17);
    }
}

@end
