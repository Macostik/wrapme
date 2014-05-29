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
#import "WLNavigation.h"
#import "WLAPIManager.h"
#import "WLWrapViewController.h"
#import "WLCameraViewController.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "WLImageCache.h"
#import "WLImageFetcher.h"
#import "UIImage+Resize.h"
#import "UIView+Shorthand.h"
#import "WLUser.h"
#import "UIButton+Additions.h"
#import "WLWrapBroadcaster.h"
#import "NSString+Additions.h"
#import "WLBorderView.h"
#import "UIColor+CustomColors.h"

@interface WLCreateWrapViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, WLContributorCellDelegate, WLCameraViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet WLBorderView *nameBorderView;
@property (weak, nonatomic) IBOutlet UIView *coverButtonView;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UITableView *contributorsTableView;
@property (strong, nonatomic) IBOutlet UIView *noContributorsView;
@property (nonatomic, readonly) BOOL isNewWrap;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (strong, nonatomic) WLWrap* editingWrap;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end

@implementation WLCreateWrapViewController

@synthesize wrap = _wrap;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	[self verifyStartAndDoneButton];
	self.coverView.image = self.isNewWrap ? self.coverView.image : nil;
	if (!self.isNewWrap) {
		[self configureWrapEditing];
	}
	
	[self setTranslucent];
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
	self.contributorsTableView.tableFooterView = self.editingWrap.contributors.nonempty ? nil : self.noContributorsView;
}

- (void)configureWrapEditing {
	self.nameField.text = self.editingWrap.name;
	self.coverView.url = self.editingWrap.picture.medium;
	self.startButton.hidden = YES;
	self.doneButton.hidden = NO;
	self.titleLabel.text = @"Edit wrap";
	if (![self.editingWrap.contributor isCurrentUser]) {
		self.coverButtonView.hidden = YES;
		self.coverView.height = self.coverView.width;
		self.nameField.userInteractionEnabled = NO;
		self.nameBorderView.strokeColor = [UIColor clearColor];
	}
}

- (void)verifyStartAndDoneButton {
	BOOL enabled = self.editingWrap.name.nonempty;
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
			if (![self.wrap.contributors containsEntry:contributor]) {
				contributorsChanged = YES;
				break;
			}
		}
	}
	
	if (nameChanged || coverChanged || contributorsChanged) {
		[self lock];
		[self.spinner startAnimating];
		__weak typeof(self)weakSelf = self;
		[self.editingWrap update:^(WLWrap *wrap) {
			[weakSelf.wrap updateWithObject:wrap];
			[weakSelf.spinner stopAnimating];
			[weakSelf dismiss];
			[weakSelf unlock];
		} failure:^(NSError *error) {
			[error show];
			[weakSelf.spinner stopAnimating];
			[weakSelf unlock];
		}];
	} else {
		[self dismiss];
	}
}

- (void)lock {
	for (UIView* subview in self.view.subviews) {
		subview.userInteractionEnabled = NO;
	}
}

- (void)unlock {
	for (UIView* subview in self.view.subviews) {
		subview.userInteractionEnabled = YES;
	}
}

- (IBAction)start:(id)sender {
	[self.spinner startAnimating];
	__weak typeof(self)weakSelf = self;
	[self lock];
	[self.editingWrap create:^(WLWrap *wrap) {
		[weakSelf.spinner stopAnimating];
		WLWrapViewController* wrapController = [WLWrapViewController instantiate];
		wrapController.wrap = wrap;
		[weakSelf unlock];
		[weakSelf.parentViewController.navigationController pushViewController:wrapController animated:YES];
		[weakSelf dismiss:WLWrapTransitionFromLeft];
	} failure:^(NSError *error) {
		[error show];
		[weakSelf.spinner stopAnimating];
		[weakSelf unlock];
	}];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [self.editingWrap.contributors count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WLContributorCell* cell = [tableView dequeueReusableCellWithIdentifier:[WLContributorCell reuseIdentifier]];
	WLUser* contributor = self.editingWrap.contributors[indexPath.section];
    cell.item = contributor;
	if ([self.editingWrap.contributor isCurrentUser]) {
		cell.deletable = ![contributor isCurrentUser];
	} else {
		cell.deletable = ![self.wrap.contributors containsEntry:contributor];
	}
    return cell;
}

#pragma mark - UITextFieldDelegate

- (IBAction)textFieldDidChange:(UITextField *)sender {
	if (sender.text.length > WLWrapNameLimit) {
		sender.text = [sender.text substringToIndex:WLWrapNameLimit];
	}
	self.editingWrap.name = sender.text;
	[self verifyStartAndDoneButton];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

#pragma mark - WLContributorCellDelegate

- (void)contributorCell:(WLContributorCell *)cell didRemoveContributor:(WLUser *)contributor {
	self.editingWrap.contributors = (id)[self.editingWrap.contributors usersByRemovingUser:contributor];
	[self refreshContributorsTableView];
}

#pragma mark - WLCameraViewControllerDelegate

- (void)cameraViewController:(WLCameraViewController *)controller didFinishWithImage:(UIImage *)image {
	self.coverView.image = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill
													   bounds:self.coverView.retinaSize
										 interpolationQuality:kCGInterpolationDefault];
	__weak typeof(self)weakSelf = self;
	[[WLImageCache cache] setImage:image completion:^(NSString *path) {
		weakSelf.editingWrap.picture.large = path;
	}];
	
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraViewControllerDidCancel:(WLCameraViewController *)controller {
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
