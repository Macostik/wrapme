//
//  WLHomeViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 19.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLHomeViewController.h"
#import "WLWrapCell.h"
#import "WLWrap.h"
#import "WLCandy.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "WLAPIManager.h"
#import "WLWrapViewController.h"
#import "UIStoryboard+Additions.h"
#import "UIView+Shorthand.h"
#import "WLCameraViewController.h"

@interface WLHomeViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *headerEntryViews;
@property (weak, nonatomic) IBOutlet UIView *headerWrapView;
@property (weak, nonatomic) IBOutlet UILabel *headerWrapNameLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *noWrapsView;
@property (strong, nonatomic) IBOutlet UITextField *typeMessageTextField;
@property (weak, nonatomic) IBOutlet UIView *messageView;
@property (strong, nonatomic) NSArray* wraps;

@end

@implementation WLHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	self.tableView.hidden = YES;
	self.noWrapsView.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	__weak typeof(self)weakSelf = self;
	[[WLAPIManager instance] wraps:^(id object) {
		weakSelf.wraps = object;
	} failure:^(NSError *error) {
		[error show];
	}];
}

- (void)setWraps:(NSArray *)wraps {
	_wraps = wraps;
	
	BOOL hasWraps = [_wraps count] > 0;
	self.tableView.hidden = !hasWraps;
	self.noWrapsView.hidden = hasWraps;
	if (hasWraps) {
		[self updateHeaderView];
	}
	[self.tableView reloadData];
}

- (void)updateHeaderView {
	WLWrap* wrap = [self.wraps lastObject];
	self.headerWrapNameLabel.text = wrap.name;
	[wrap.candies enumerateObjectsUsingBlock:^(WLCandy* candy, NSUInteger idx, BOOL *stop) {
		if (idx < [self.headerEntryViews count]) {
			UIImageView* imageView = [self.headerEntryViews objectAtIndex:idx];
			imageView.image = nil;
			[imageView setImageWithURL:[NSURL URLWithString:candy.cover]];
		} else {
			*stop = YES;
		}
	}];
}

- (IBAction)typeMessage:(UIButton *)sender {
	if (self.messageView.hidden) {
		self.tableView.frame = CGRectMake(self.tableView.x, self.tableView.y + self.messageView.height, self.tableView.width, self.tableView.height - self.messageView.height);
		self.messageView.hidden = NO;
	}
	else {
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue isWrapSegue]) {
		WLWrap* wrap = [self.wraps objectAtIndex:[self.tableView indexPathForSelectedRow].row];
		[(WLWrapViewController* )segue.destinationViewController setWrap:wrap];
	} else if ([segue isCameraSegue]) {
		WLCameraViewController* cameraController = segue.destinationViewController;
		cameraController.mode = WLCameraModeFullSize;
	}
}

#pragma mark - <UITableViewDataSource, UITableViewDelegate>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.wraps count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString* wrapCellIdentifier = @"WLWrapCell";
	WLWrapCell* cell = [tableView dequeueReusableCellWithIdentifier:wrapCellIdentifier
													   forIndexPath:indexPath];
	cell.item = [self.wraps objectAtIndex:indexPath.row];
	return cell;
}

#pragma mark - <UITextFieldDelegate>

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[self hideViewAndSendMessage];
	return YES;
}

@end
