//
//  WLWrapViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapViewController.h"
#import "WLWrap.h"
#import "WLWrapCandiesCell.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "WLCandy.h"
#import "NSDate+Formatting.h"
#import "WLWrapDay.h"
#import "UIView+Shorthand.h"
#import "UIStoryboard+Additions.h"
#import "WLCameraViewController.h"
#import "WLImage.h"

@interface WLWrapViewController () <UITextFieldDelegate, WLCameraViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UITableView* tableView;
@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *contributorsLabel;
@property (weak, nonatomic) IBOutlet UIView *messageView;
@property (strong, nonatomic) NSMutableArray * wrapDays;
@property (weak, nonatomic) IBOutlet UITextField *typeMessageTextField;

@end

@implementation WLWrapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	[self.coverView setImageWithURL:[NSURL URLWithString:self.wrap.cover]];
	self.nameLabel.text = self.wrap.name;
	
	[self sortCandiesInWrap];
}

- (void) sortCandiesInWrap {
	NSMutableArray* candies = [self.wrap.candies mutableCopy];
	
	NSMutableArray* wrapDays = [NSMutableArray array];
	
	while ([candies count] > 0) {
		WLCandy* candy = [candies firstObject];
		NSDate* startDate = [candy.modified beginOfDay];
		NSDate* endDate = [candy.modified endOfDay];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(modified >= %@) AND (modified <= %@)", startDate, endDate];
		NSArray *dayCandies = [candies filteredArrayUsingPredicate:predicate];
		WLWrapDay * wrapDay = [WLWrapDay new];
		wrapDay.modified = candy.modified;
		wrapDay.candies = dayCandies;
		[wrapDays addObject:wrapDay];
		[candies removeObjectsInArray:dayCandies];
	}
	
	static NSSortDescriptor* sortDescriptor = nil;
	if (!sortDescriptor) {
		sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"modified" ascending:YES];
	}
	[wrapDays sortUsingDescriptors:@[sortDescriptor]];
	
	self.wrapDays = [wrapDays copy];
	
	[self.tableView reloadData];
}

- (IBAction)typeMessage:(UIButton *)sender {
	if (self.messageView.hidden) {
		self.tableView.frame = CGRectMake(self.tableView.x, self.tableView.y + self.messageView.height, self.tableView.width, self.tableView.height - self.messageView.height);
		self.messageView.hidden = NO;
	} else {
		[self hideView];
	}
}

- (IBAction)sendMessage:(UIButton *)sender {
	[self hideViewAndSendMessage];
}

- (void)hideViewAndSendMessage {
	[self hideView];
	[self sendMessage];
}

- (void)sendMessage {
	
}

- (void)hideView {
	self.messageView.hidden = YES;
	self.tableView.frame = CGRectMake(self.tableView.x, self.tableView.y - self.messageView.height, self.tableView.width, self.tableView.height + self.messageView.height);
	[self.typeMessageTextField resignFirstResponder];
	self.typeMessageTextField.text = nil;
}

- (IBAction)back:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue isCameraSegue]) {
		WLCameraViewController* cameraController = segue.destinationViewController;
		cameraController.mode = WLCameraModeFullSize;
		cameraController.delegate = self;
	}
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.wrapDays.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WLWrapCandiesCell* cell = [tableView dequeueReusableCellWithIdentifier:[WLWrapCandiesCell reuseIdentifier]];
	cell.item = [self.wrapDays objectAtIndex:indexPath.row];
    return cell;
}

#pragma mark - <UITextFieldDelegate>

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[self hideViewAndSendMessage];
	return YES;
}

#pragma mark - WLCameraViewControllerDelegate

- (void)cameraViewController:(WLCameraViewController *)controller didFinishWithImage:(UIImage *)image {
	WLImage* candy = [WLImage entry];
	candy.url = @"http://placeimg.com/135/111/any";
	candy.thumbnail = @"http://placeimg.com/123/111/any";
	[self.wrap addCandy:candy];
	[self sortCandiesInWrap];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraViewControllerDidCancel:(WLCameraViewController *)controller {
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
