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
#import "WLLoadingView.h"
#import "WLAuthorizationRequest.h"

@interface WLWelcomeViewController ()

@property (weak, nonatomic) WLLoadingView *splash;
@property (weak, nonatomic) IBOutlet UIButton *licenseButton;
@property (weak, nonatomic) IBOutlet UIView *transparentView;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundView;

@end

@implementation WLWelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
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
    
    UIToolbar* toolbar = [[UIToolbar alloc] initWithFrame:self.transparentView.bounds];
    toolbar.tintColor = [UIColor whiteColor];
    toolbar.translucent = YES;
    toolbar.alpha = 0.96;
    toolbar.barStyle = UIBarStyleDefault;
    [self.transparentView insertSubview:toolbar atIndex:0];
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
	} makeRootViewControllerAnimated:NO];
}

- (IBAction)termsAndConditions:(id)sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.wraplive.com/welcome/terms_and_conditions"]];
}

@end
