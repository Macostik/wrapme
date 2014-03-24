//
//  WLSignUpViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 19.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLSignUpViewController.h"
#import "WLAPIManager.h"
#import "WLUser.h"

@interface WLSignUpViewController () <UIScrollViewDelegate>

@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *stepLabels;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *stepDoneViews;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *stepViews;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation WLSignUpViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.scrollView.contentSize = CGSizeMake(CGRectGetMaxX([[self.stepViews lastObject] frame]), self.scrollView.frame.size.height);
	[self updateStepLabels];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[self updateStepLabels];
}

- (void)updateStepLabels {
	NSInteger currentStep = roundf(self.scrollView.contentOffset.x / self.scrollView.frame.size.width);
	
	[self.stepLabels enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(UILabel* label, NSUInteger idx, BOOL *stop) {
		label.hidden = idx >= currentStep;
	}];
	
	[self.stepViews enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(UIView* view, NSUInteger idx, BOOL *stop) {
		view.hidden = idx < currentStep;
	}];
}

#pragma mark - User Actions

- (IBAction)editNumber:(id)sender {
	[self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x - self.scrollView.frame.size.width, self.scrollView.contentOffset.y) animated:YES];
}

- (IBAction)nextStep:(id)sender {
	[self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x + self.scrollView.frame.size.width, self.scrollView.contentOffset.y) animated:YES];
}

@end
