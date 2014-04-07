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
#import "WLProgressView.h"
#import "UIImageView+ImageLoading.h"

@interface WLCreateWrapViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, WLContributorCellDelegate, WLCameraViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UITableView *contributorsTableView;
@property (strong, nonatomic) IBOutlet UIView *noContributorsView;
@property (weak, nonatomic) IBOutlet UIView *separatorView;
@property (nonatomic, readonly) BOOL isNewWrap;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (strong, nonatomic) WLWrap* editingWrap;

@end

@implementation WLCreateWrapViewController

@synthesize wrap = _wrap;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	[self verifyStartAndDoneButton];
	[self fillDataAndUpdateLabels];
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
		controller.backfacingByDefault = YES;
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self refreshContributorsTableView];
}

- (void)refreshContributorsTableView {
	[self.contributorsTableView reloadData];
	BOOL hasContributors = [self.editingWrap.contributors count] > 0;
	self.contributorsTableView.tableFooterView = hasContributors ? nil : self.noContributorsView;
	self.separatorView.hidden = !hasContributors;
}

- (void)fillDataAndUpdateLabels {
	self.nameField.text = self.editingWrap.name;
	self.coverView.imageUrl = self.editingWrap.picture.medium;
	self.startButton.hidden = !self.isNewWrap;
	self.doneButton.hidden = self.isNewWrap;
	self.titleLabel.text = self.isNewWrap ? @"Create new wrap" : @"Change wrap settings";
}

- (void)verifyStartAndDoneButton {
	BOOL enabled = self.editingWrap.name.length > 0;
	self.startButton.enabled = enabled;
	self.doneButton.enabled = enabled;
}

#pragma mark - Actions

- (IBAction)back:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}
- (IBAction)done:(UIButton *)sender {
	__weak typeof(self)weakSelf = self;
	[[WLAPIManager instance] updateWrap:self.editingWrap success:^(id object) {
		[weakSelf.wrap updateWithObject:object];
		[weakSelf.wrap postNotificationForRequest:NO];
		[weakSelf.navigationController popViewControllerAnimated:YES];
	} failure:^(NSError *error) {
		[error show];
	}];
}

- (IBAction)start:(id)sender {
	__weak typeof(self)weakSelf = self;
	id operation = [[WLAPIManager instance] createWrap:self.editingWrap success:^(WLWrap* wrap) {
		[WLProgressView dismiss];
		[wrap postNotificationForRequest:YES];
		WLWrapViewController* wrapController = [weakSelf.storyboard wrapViewController];
		wrapController.wrap = wrap;
		NSArray* controllers = @[[weakSelf.navigationController.viewControllers firstObject],wrapController];
		[weakSelf.navigationController setViewControllers:controllers animated:YES];
	} failure:^(NSError *error) {
		[WLProgressView dismiss];
		[error show];
	}];
	[WLProgressView showWithMessage:@"Creating wrap..." operation:operation];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.editingWrap.contributors count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WLContributorCell* cell = [tableView dequeueReusableCellWithIdentifier:[WLContributorCell reuseIdentifier]];
    cell.item = [self.editingWrap.contributors objectAtIndex:indexPath.row];
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
	self.editingWrap.contributors = (id)[self.editingWrap.contributors arrayByRemovingObject:contributor];
	[self refreshContributorsTableView];
}

#pragma mark - WLCameraViewControllerDelegate

- (void)cameraViewController:(WLCameraViewController *)controller didFinishWithImage:(UIImage *)image {
	self.coverView.image = image;
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
