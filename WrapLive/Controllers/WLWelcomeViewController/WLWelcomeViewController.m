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
#import "UIStoryboard+Additions.h"
#import "WLUser.h"
#import "WLSignUpViewController.h"

@interface WLWelcomeViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *backgroundView;
@property (weak, nonatomic) IBOutlet UIButton *continueButton;

@end

@implementation WLWelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

//	NSArray *navigationArray = @[[self.storyboard homeViewController]];
//	[self.navigationController setViewControllers:navigationArray];
	
	if ([WLSession activated]) {
		self.continueButton.transform = CGAffineTransformMakeTranslation(0, self.continueButton.frame.size.height);
		__weak typeof(self)weakSelf = self;
		[self signIn:^(NSError *error) {
			[error show];
			[UIView beginAnimations:nil context:nil];
			weakSelf.continueButton.transform = CGAffineTransformIdentity;
			[UIView commitAnimations];
		}];
	}
}

- (void)signIn:(void (^)(NSError* error))failure {
	__weak typeof(self)weakSelf = self;
	WLUser* user = [WLSession user];
	[[WLAPIManager instance] signIn:user success:^(id object) {
		[weakSelf checkNameAndAvatar:failure];
	} failure:failure];
}

- (void) checkNameAndAvatar:(void (^)(NSError* error))failure {
	__weak typeof(self)weakSelf = self;
	[[WLAPIManager instance] me:^(WLUser* user) {
		if (user.registrationCompleted) {
			NSArray *navigationArray = @[[weakSelf.storyboard homeViewController]];
			[weakSelf.navigationController setViewControllers:navigationArray];
		}
		else {
			WLSignUpViewController * controller = [weakSelf.storyboard signUpViewController];
			controller.registrationNotCompleted = YES;
			NSArray *navigationArray = @[controller];
			[weakSelf.navigationController setViewControllers:navigationArray];
		}
	} failure:failure];
}

@end
