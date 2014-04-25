//
//  WLCreateWrapViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 25.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCreateWrapViewController.h"
#import "WLContributorCell.h"
#import "WLWrap.h"
#import "WLContributorsViewController.h"
#import "NSArray+Additions.h"
#import "UIStoryboard+Additions.h"
#import "WLAPIManager.h"
#import "WLWrapViewController.h"
#import "WLCameraViewController.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "UIImage+WLStoring.h"
#import "UIImageView+ImageLoading.h"
#import "UIImage+Resize.h"
#import "UIView+Shorthand.h"
#import "WLUser.h"
#import "UIButton+Additions.h"

@interface WLCreateWrapViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, WLContributorCellDelegate, WLCameraViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UITableView *contributorsTableView;
@property (strong, nonatomic) IBOutlet UIView *noContributorsView;
@property (nonatomic, readonly) BOOL isNewWrap;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (strong, nonatomic) WLWrap* editingWrap;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property (nonatomic) WLWrapTransition transition;

@end

@implementation WLCreateWrapViewController

@synthesize wrap = _wrap;

- (void)presentInViewController:(UIViewController *)controller transition:(WLWrapTransition)transition {
	self.transition = transition;
	self.view.frame = controller.view.bounds;
	[controller.view addSubview:self.view];
	[controller addChildViewController:self];
	if (transition != WLWrapTransitionWithoutAnimation) {
		__weak typeof(self)weakSelf = self;
		if (transition == WLWrapTransitionFromBottom) {
			self.view.transform = CGAffineTransformMakeTranslation(0, self.view.height);
			[UIView animateWithDuration:0.33f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
				weakSelf.view.transform = CGAffineTransformIdentity;
			} completion:^(BOOL finished) {
			}];
		} else if (transition == WLWrapTransitionFromRight) {
			self.view.transform = CGAffineTransformMakeTranslation(self.view.width, 0);
			[UIView animateWithDuration:0.33f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
				weakSelf.view.transform = CGAffineTransformIdentity;
			} completion:^(BOOL finished) {
			}];
		}
	}
}

- (void)dismiss:(WLWrapTransition)transition {
	if (transition != WLWrapTransitionWithoutAnimation) {
		__weak typeof(self)weakSelf = self;
		if (transition == WLWrapTransitionFromBottom) {
			[UIView animateWithDuration:0.33f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
				weakSelf.view.transform = CGAffineTransformMakeTranslation(0, weakSelf.view.height);
			} completion:^(BOOL finished) {
				[weakSelf.view removeFromSuperview];
				[weakSelf removeFromParentViewController];
			}];
		} else if (transition == WLWrapTransitionFromRight) {
			[UIView animateWithDuration:0.33f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
				weakSelf.view.transform = CGAffineTransformMakeTranslation(weakSelf.view.width, 0);
			} completion:^(BOOL finished) {
				[weakSelf.view removeFromSuperview];
				[weakSelf removeFromParentViewController];
			}];
		}
	} else {
		[self.view removeFromSuperview];
		[self removeFromParentViewController];
	}
}

- (void)dismiss {
	[self dismiss:self.transition];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	[self verifyStartAndDoneButton];
	self.coverView.image = self.isNewWrap ? self.coverView.image : nil;
	if (!self.isNewWrap) {
		[self configureWrapEditing];
	}
	
	self.view.backgroundColor = [UIColor clearColor];
	UIToolbar* toolbar = [[UIToolbar alloc] initWithFrame:self.view.bounds];
	toolbar.translucent = YES;
	[self.view insertSubview:toolbar atIndex:0];
}

- (BOOL)isNewWrap {
	return self.wrap == nil;
}

- (WLWrap *)editingWrap {
	if (!_editingWrap) {
		_editingWrap = [WLWrap entry];
	}
	return _editingWrap;
}

- (void)setWrap:(WLWrap *)wrap {
	_wrap = wrap;
	self.editingWrap = [wrap copy];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue isContributorsSegue]) {
		WLContributorsViewController* controller = segue.destinationViewController;
		controller.wrap = self.editingWrap;
	} else if ([segue isCameraSegue]) {
		WLCameraViewController* controller = segue.destinationViewController;
		controller.delegate = self;
		controller.mode = WLCameraModeCover;
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self refreshContributorsTableView];
}

- (void)refreshContributorsTableView {
	[self.contributorsTableView reloadData];
	[self refreshFooterView];
}

- (void)refreshFooterView {
	for (WLUser* contributor in self.editingWrap.contributors) {
		if (![contributor isCurrentUser]) {
			self.contributorsTableView.tableFooterView = nil;
			return;
		}
	}
	self.contributorsTableView.tableFooterView = self.noContributorsView;
}

- (void)configureWrapEditing {
	self.nameField.text = self.editingWrap.name;
	self.coverView.imageUrl = self.editingWrap.picture.medium;
	self.startButton.hidden = YES;
	self.doneButton.hidden = NO;
	self.titleLabel.text = @"Edit wrap";
	self.coverView.superview.userInteractionEnabled = [self.editingWrap.contributor isCurrentUser];
	self.nameField.userInteractionEnabled = [self.editingWrap.contributor isCurrentUser];
}

- (void)verifyStartAndDoneButton {
	BOOL enabled = self.editingWrap.name.length > 0;
	self.startButton.active = enabled;
	self.doneButton.active = enabled;
}

#pragma mark - Actions

- (IBAction)back:(id)sender {
	[self dismiss];
}

- (IBAction)done:(UIButton *)sender {
	BOOL nameChanged = ![self.wrap.name isEqualToString:self.editingWrap.name];
	BOOL coverChanged = ![self.wrap.picture.large isEqualToString:self.editingWrap.picture.large];
	BOOL contributorsChanged = NO;
	
	if ([self.wrap.contributors count] != [self.editingWrap.contributors count]) {
		contributorsChanged = YES;
	} else {
		for (WLUser* contributor in self.editingWrap.contributors) {
			if (![self.wrap.contributors containsObject:contributor byBlock:[WLUser equalityBlock]]) {
				contributorsChanged = YES;
				break;
			}
		}
	}
	
	if (nameChanged || coverChanged || contributorsChanged) {
		self.view.userInteractionEnabled = NO;
		[self.spinner startAnimating];
		__weak typeof(self)weakSelf = self;
		[[WLAPIManager instance] updateWrap:self.editingWrap success:^(id object) {
			[weakSelf.wrap updateWithObject:object];
			[weakSelf.wrap broadcastChange];
			[weakSelf.spinner stopAnimating];
			[weakSelf dismiss];
			weakSelf.view.userInteractionEnabled = YES;
		} failure:^(NSError *error) {
			[error show];
			[weakSelf.spinner stopAnimating];
			weakSelf.view.userInteractionEnabled = YES;
		}];
	} else {
		[self dismiss];
	}
}

- (IBAction)start:(id)sender {
	[self.spinner startAnimating];
	__weak typeof(self)weakSelf = self;
	self.view.userInteractionEnabled = NO;
	[[WLAPIManager instance] createWrap:self.editingWrap success:^(WLWrap* wrap) {
		[wrap broadcastCreation];
		[weakSelf.spinner stopAnimating];
		WLWrapViewController* wrapController = [weakSelf.storyboard wrapViewController];
		wrapController.wrap = wrap;
		weakSelf.view.userInteractionEnabled = YES;
		[weakSelf.parentViewController.navigationController pushViewController:wrapController animated:YES];
		[weakSelf dismiss];
	} failure:^(NSError *error) {
		[error show];
		[weakSelf.spinner stopAnimating];
		weakSelf.view.userInteractionEnabled = YES;
	}];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [self.editingWrap.contributors count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	WLUser* contributor = [self.editingWrap.contributors objectAtIndex:section];
    return [contributor isCurrentUser] ? 0 : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WLContributorCell* cell = [tableView dequeueReusableCellWithIdentifier:[WLContributorCell reuseIdentifier]];
	WLUser* contributor = self.editingWrap.contributors[indexPath.section];
    cell.item = contributor;
	if ([self.editingWrap.contributor isCurrentUser]) {
		cell.deletable = YES;
	} else {
		cell.deletable = ![contributor isEqualToUser:self.editingWrap.contributor];
	}
    return cell;
}

#pragma mark - UITextFieldDelegate

- (IBAction)textFieldDidChange:(UITextField *)sender {
	self.editingWrap.name = sender.text;
	[self verifyStartAndDoneButton];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

#pragma mark - WLContributorCellDelegate

- (void)contributorCell:(WLContributorCell *)cell didRemoveContributor:(WLUser *)contributor {
	self.editingWrap.contributors = (id)[self.editingWrap.contributors arrayByRemovingUser:contributor];
	[self refreshContributorsTableView];
}

#pragma mark - WLCameraViewControllerDelegate

- (void)cameraViewController:(WLCameraViewController *)controller didFinishWithImage:(UIImage *)image {
	self.coverView.image = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill
													   bounds:self.coverView.retinaSize
										 interpolationQuality:kCGInterpolationDefault];
	__weak typeof(self)weakSelf = self;
	[image storeAsCover:^(NSString *path) {
		weakSelf.editingWrap.picture.large = path;
	}];
	
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraViewControllerDidCancel:(WLCameraViewController *)controller {
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
