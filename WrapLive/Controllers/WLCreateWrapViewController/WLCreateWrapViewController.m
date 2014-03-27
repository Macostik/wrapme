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

@interface WLCreateWrapViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, WLContributorCellDelegate, WLCameraViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UITableView *contributorsTableView;
@property (weak, nonatomic) IBOutlet UIView *noContributorsView;

@property (strong, nonatomic) WLWrap* wrap;

@end

@implementation WLCreateWrapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (WLWrap *)wrap {
	if (!_wrap) {
		_wrap = [WLWrap wrap];
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
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self refreshContributorsTableView];
}

- (void)refreshContributorsTableView {
	[self.contributorsTableView reloadData];
	BOOL hasContributors = [self.wrap.contributors count] > 0;
	self.noContributorsView.hidden = hasContributors;
	self.contributorsTableView.hidden = !hasContributors;
}

#pragma mark - Actions

- (IBAction)back:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)start:(id)sender {
	__weak typeof(self)weakSelf = self;
	self.wrap.name = self.nameField.text;
	self.wrap.cover = @"http://placeimg.com/111/111/any";
	[[WLAPIManager instance] createWrap:self.wrap success:^(id object) {
		[[WLWrap dummyWraps] addObject:weakSelf.wrap];
		WLWrapViewController* wrapController = [weakSelf.storyboard wrapViewController];
		wrapController.wrap = weakSelf.wrap;
		NSArray* controllers = @[[weakSelf.navigationController.viewControllers firstObject],wrapController];
		[weakSelf.navigationController setViewControllers:controllers animated:YES];
	} failure:^(NSError *error) {
		[error show];
	}];
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

#pragma mark - WLContributorCellDelegate

- (void)contributorCell:(WLContributorCell *)cell didRemoveContributor:(WLUser *)contributor {
	self.wrap.contributors = [self.wrap.contributors arrayByRemovingObject:contributor];
	[self refreshContributorsTableView];
}

#pragma mark - WLCameraViewControllerDelegate

- (void)cameraViewController:(WLCameraViewController *)controller didFinishWithImage:(UIImage *)image {
	self.coverView.image = image;
	__weak typeof(self)weakSelf = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/WrapLiveAvatar.jpg"];
		[UIImageJPEGRepresentation(image,1.0) writeToFile:path atomically:YES];
		weakSelf.wrap.cover = path;
    });
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraViewControllerDidCancel:(WLCameraViewController *)controller {
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
