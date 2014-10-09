//
//  WLViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 19.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "NSString+Additions.h"
#import "UIColor+CustomColors.h"
#import "UIFont+CustomFonts.h"
#import "UIView+GestureRecognizing.h"
#import "UIView+Shorthand.h"
#import "WLAPIManager.h"
#import "WLAuthorization.h"
#import "WLAuthorizationRequest.h"
#import "WLHomeViewController.h"
#import "WLLoadingView.h"
#import "WLNavigation.h"
#import "WLSession.h"
#import "WLSignUpViewController.h"
#import "WLTermsAndConditionsKeys.h"
#import "WLUser.h"
#import "WLWelcomeViewController.h"

typedef enum : NSUInteger {
    WLFlipDirectionLeft,
    WLFlipDirectionRight,
} WLFlipDirection;

@interface WLWelcomeViewController () <UIGestureRecognizerDelegate>

@property (weak, nonatomic) WLLoadingView *splash;
@property (weak, nonatomic) IBOutlet UIButton *licenseButton;
@property (strong, nonatomic) IBOutlet UIView *transparentView;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundView;
@property (strong, nonatomic) IBOutlet UIView *placeholderView;
@property (weak, nonatomic) IBOutlet UITextView *termsAndConditionsTextView;

@end

@implementation WLWelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.placeholderView.layer.cornerRadius = 5.0f;
    self.placeholderView.layer.masksToBounds = YES;
    [self.placeholderView removeFromSuperview];
    
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
    [self.termsAndConditionsTextView addTapGestureRecognizingDelegate:self
                                                       block:^(UIGestureRecognizer *recognizer) {
                                                           [weakSelf flipAnimationView:WLFlipDirectionLeft];
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
	} makeRootViewControllerAnimated:WLFlipDirectionLeft];
}

- (IBAction)termsAndConditions:(id)sender {
    [self flipAnimationView:WLFlipDirectionRight];
}

- (void)flipAnimationView:(WLFlipDirection)direction {
    UIView *fromView = direction == WLFlipDirectionLeft ? self.placeholderView : self.transparentView;
    UIView *toView = direction ==   WLFlipDirectionLeft ? self.transparentView : self.placeholderView;
    NSInteger option = direction == WLFlipDirectionLeft? UIViewAnimationOptionTransitionFlipFromRight :
                                                         UIViewAnimationOptionTransitionFlipFromLeft;
    
    [UIView transitionFromView:fromView
                        toView:toView
                      duration:0.75
                       options:option
                    completion:NULL];
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
    return ![otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]];
}

@end
