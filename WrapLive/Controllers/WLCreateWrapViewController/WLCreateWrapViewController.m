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

@interface WLCreateWrapViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, WLContributorCellDelegate, WLCameraViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UITableView *contributorsTableView;
@property (strong, nonatomic) IBOutlet UIView *noContributorsView;
@property (weak, nonatomic) IBOutlet UIView *separatorView;
@property (nonatomic) BOOL isNewWrap;
@property (strong, nonatomic) NSString * notChangedWrapName;


@property (weak, nonatomic) IBOutlet UILabel *titleLabel;


@end

@implementation WLCreateWrapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	[self verifyStartAndDoneButton];
}

- (WLWrap *)wrap {
	if (!_wrap) {
		_wrap = [WLWrap entry];
		self.isNewWrap = YES;
	}
	else {
		self.notChangedWrapName = _wrap.name;
	}
	return _wrap;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue isContributorsSegue]) {
		WLContributorsViewController* controller = segue.destinationViewController;
		controller.wrap = self.wrap;
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
	[self fillDataAndUpdateLabels];
	BOOL hasContributors = [self.wrap.contributors count] > 0;
	self.contributorsTableView.tableFooterView = hasContributors ? nil : self.noContributorsView;
	self.separatorView.hidden = !hasContributors;
}

- (void)fillDataAndUpdateLabels {
	self.nameField.text = self.wrap.name;
	[self.coverView setImageWithURL:[NSURL URLWithString:self.wrap.picture.large]];
	self.startButton.hidden = !self.isNewWrap;
	self.doneButton.hidden = self.isNewWrap;
	self.titleLabel.text = self.isNewWrap ? @"Create new wrap" : @"Change wrap settings";
}

- (void)verifyStartAndDoneButton {
	BOOL enabled = self.wrap.name && (![self.wrap.name isEqualToString:@""]) ? YES : NO;
	self.startButton.enabled = enabled;
	self.doneButton.enabled = enabled;
}

- (void) postNotificationForRequest:(BOOL)isNeedRequest {
	[[NSNotificationCenter defaultCenter] postNotificationName:WLWrapChangesNotification
														object:nil
													  userInfo:@{
																 @"wrap":self.wrap,
																 @"isNeedRequest":[NSNumber numberWithBool:isNeedRequest]
																 }];
}

#pragma mark - Actions

- (IBAction)back:(id)sender {
	self.wrap.name = self.notChangedWrapName;
	[self.navigationController popViewControllerAnimated:YES];
}
- (IBAction)done:(UIButton *)sender {
	__weak typeof(self)weakSelf = self;
	[[WLAPIManager instance] updateWrap:self.wrap success:^(id object) {
		[weakSelf.navigationController popViewControllerAnimated:YES];
		[self postNotificationForRequest:NO];
	} failure:^(NSError *error) {
		[error show];
	}];
}

- (IBAction)start:(id)sender {
	__weak typeof(self)weakSelf = self;
	id operation = [[WLAPIManager instance] createWrap:self.wrap success:^(id object) {
		[WLProgressView dismiss];
		WLWrapViewController* wrapController = [weakSelf.storyboard wrapViewController];
		wrapController.wrap = object;
		NSArray* controllers = @[[weakSelf.navigationController.viewControllers firstObject],wrapController];
		[weakSelf.navigationController setViewControllers:controllers animated:YES];
		[self postNotificationForRequest:YES];
	} failure:^(NSError *error) {
		[WLProgressView dismiss];
		[error show];
	}];
	[WLProgressView showWithMessage:@"Creating wrap..." operation:operation];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.wrap.contributors count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WLContributorCell* cell = [tableView dequeueReusableCellWithIdentifier:[WLContributorCell reuseIdentifier]];
    cell.item = [self.wrap.contributors objectAtIndex:indexPath.row];
    return cell;
}

#pragma mark - UITextFieldDelegate

- (IBAction)textFieldDidChange:(UITextField *)sender {
	self.wrap.name = sender.text;
	[self verifyStartAndDoneButton];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}



#pragma mark - WLContributorCellDelegate

- (void)contributorCell:(WLContributorCell *)cell didRemoveContributor:(WLUser *)contributor {
	self.wrap.contributors = (id)[self.wrap.contributors arrayByRemovingObject:contributor];
	[self refreshContributorsTableView];
}

#pragma mark - WLCameraViewControllerDelegate

- (void)cameraViewController:(WLCameraViewController *)controller didFinishWithImage:(UIImage *)image {
	self.coverView.image = image;
	__weak typeof(self)weakSelf = self;
	[image storeAsCover:^(NSString *path) {
		weakSelf.wrap.picture.large = path;
	}];
	
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraViewControllerDidCancel:(WLCameraViewController *)controller {
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
