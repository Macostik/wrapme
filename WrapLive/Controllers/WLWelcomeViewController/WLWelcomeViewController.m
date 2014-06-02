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

@interface WLWelcomeViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *backgroundView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIButton *licenseButton;

@end

@implementation WLWelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	self.bottomView.hidden = YES;
	if ([[WLAuthorization currentAuthorization] canAuthorize]) {
		__weak typeof(self)weakSelf = self;
		[[WLAPIManager instance] signIn:[WLAuthorization currentAuthorization] success:^(WLUser* user) {
			if (user.name.nonempty) {
				[weakSelf presentHomeViewController];
			} else {
				[weakSelf continueSignUp];
			}
		} failure:^(NSError *error) {
			if ([error isNetworkError]) {
				[weakSelf presentHomeViewController];
			} else {
				[weakSelf showBottomView];
			}
		}];
	} else {
		[self showBottomView];
	}
}

- (void)showBottomView {
	self.bottomView.transform = CGAffineTransformMakeTranslation(0, self.bottomView.frame.size.height);
	self.bottomView.hidden = NO;
	[self underlineLicenseButton];
	__weak typeof(self)weakSelf = self;
	[UIView animateWithDuration:0.25f animations:^{
		weakSelf.bottomView.transform = CGAffineTransformIdentity;
	}];
	[self.spinner removeFromSuperview];
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
	[WLHomeViewController instantiateAndMakeRootViewControllerAnimated:NO];
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
