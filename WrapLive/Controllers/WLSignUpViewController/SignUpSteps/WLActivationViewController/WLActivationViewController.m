//
//  WLActivationViewController.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/25/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLActivationViewController.h"
#import "WLUser.h"
#import "WLAPIManager.h"
#import "WLProfileInformationViewController.h"

@interface WLActivationViewController ()

@property (strong, nonatomic) IBOutlet UIView *activationView;
@property (strong, nonatomic) IBOutlet UITextField *activationTextField;

@property (strong, nonatomic) IBOutlet UIView *inProgressView;
@property (strong, nonatomic) IBOutlet UILabel *inProgressPhoneLabel;
@property (strong, nonatomic) IBOutlet UIView *successfulView;
@property (strong, nonatomic) IBOutlet UILabel *successfulPhoneLabel;
@property (strong, nonatomic) IBOutlet UIImageView *successfulImageView;
@property (strong, nonatomic) IBOutlet UIView *failedView;
@property (strong, nonatomic) IBOutlet UILabel *failedPhoneLabel;
@property (strong, nonatomic) IBOutlet UIImageView *failedImageView;

@end

@implementation WLActivationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	self.activationTextField.inputAccessoryView = [self addToolBarWithSelectorsCancel:@selector(activationCancel:) andDone:@selector(activationDone:)];
}

- (IBAction)activateCode:(id)sender {
	
	self.activationView.hidden = YES;
	self.inProgressView.hidden = NO;
	
	self.currentUser.activationCode = self.activationTextField.text;
	//TODO: verify request
	[[WLAPIManager instance] activate:self.currentUser success:^(id object) {
		self.inProgressView.hidden = YES;
		self.successfulView.hidden = NO;
		self.successfulPhoneLabel.text = self.phoneNumberLabel.text;
	} failure:^(NSError *error) {
		self.inProgressView.hidden = YES;
		self.failedView.hidden = NO;
		self.failedPhoneLabel.text = self.phoneNumberLabel.text;
	}];
}

- (IBAction)editNumber:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)tryAgain:(id)sender {
	self.activationTextField.text = nil;
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)continue:(id)sender {
	WLProfileInformationViewController * controller = [WLProfileInformationViewController new];
	[self.navigationController pushViewController:controller animated:YES];
}

- (void)activationCancel:(id)sender {
	self.activationTextField.text = nil;
	[self.activationTextField resignFirstResponder];
}

- (void)activationDone:(id)sender {
	
	[self.activationTextField resignFirstResponder];
}

- (UIToolbar *) addToolBarWithSelectorsCancel:(SEL)cancel andDone:(SEL)done
{
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    UIBarButtonItem *item1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                           target:self
                                                                           action:cancel];
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                           target:self
                                                                           action:cancel];
    UIBarButtonItem *item3 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                           target:self
                                                                           action:done];
    toolbar.items = @[item1, item2, item3];
    return toolbar;
}

//- (void)scrollTextFieldToVisible:(UITextField *)textField
//{
//    [self.scrollView setContentOffset:CGPointZero animated:YES];
//    
//    if ([textField isFirstResponder])
//    {
//		//		float toolBarHeight = textField.inputAccessoryView ? 44 : 0;
//        CGPoint scrollPoint = CGPointMake(self.scrollView.contentOffset.x, textField.frame.origin.y - 50);
//        [self.scrollView setContentOffset:scrollPoint animated:YES];
//    }
//}
//
//#pragma mark - UITextFieldDelegate
//
//- (void)textFieldDidBeginEditing:(UITextField *)textField {
//	
//	[self scrollTextFieldToVisible:textField];
//}
//
//- (void)textFieldDidEndEditing:(UITextField *)textField {
//	CGPoint scrollPoint = CGPointMake(self.scrollView.contentOffset.x, 0.0);
//	[self.scrollView setContentOffset:scrollPoint animated:NO];
//}

@end
