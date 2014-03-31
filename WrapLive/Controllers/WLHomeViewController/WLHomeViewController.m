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
#import "UIImageView+ImageLoading.h"
#import "WLAPIManager.h"
#import "WLWrapViewController.h"
#import "UIStoryboard+Additions.h"
#import "UIView+Shorthand.h"
#import "WLCameraViewController.h"
#import "NSArray+Additions.h"
#import "NSDate+Formatting.h"
#import "StreamView.h"
#import "WLWrapDataViewController.h"
#import "UIColor+CustomColors.h"
#import "WLPicture.h"
#import "WLImage.h"
#import "WLConversation.h"
#import "WLComposeBar.h"
#import "WLComposeContainer.h"
#import "WLComment.h"

@interface WLHomeViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, WLCameraViewControllerDelegate, StreamViewDelegate, WLComposeBarDelegate>

@property (weak, nonatomic) IBOutlet StreamView *topWrapStreamView;
@property (weak, nonatomic) IBOutlet UIView *headerWrapView;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UILabel *headerWrapNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *headerWrapCreatedAtLabel;
@property (weak, nonatomic) IBOutlet UILabel *headerWrapAuthorsLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *noWrapsView;
@property (weak, nonatomic) IBOutlet WLComposeContainer *composeContainer;
@property (strong, nonatomic) NSArray* wraps;
@property (strong, nonatomic) WLWrap* topWrap;

@end

@implementation WLHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	self.composeContainer.hidden = YES;
	self.noWrapsView.hidden = YES;
	
	self.topWrapStreamView.reusableViewLoadingType = StreamViewReusableViewLoadingTypeInit;
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

- (void)setTopWrap:(WLWrap *)topWrap {
	_topWrap = topWrap;
	[self updateHeaderViewWithWrap:topWrap];
}

- (void)setWraps:(NSArray *)wraps {
	wraps = [wraps sortedEntries];
	WLWrap* topWrap = [wraps firstObject];
	_wraps = [wraps arrayByRemovingObject:topWrap];
	self.composeContainer.hidden = (topWrap == nil);
	self.noWrapsView.hidden = (topWrap != nil);
	self.topWrap = topWrap;
	[self.tableView reloadData];
}

- (void)updateHeaderViewWithWrap:(WLWrap*)wrap {
	self.headerWrapNameLabel.text = wrap.name;
	self.headerWrapCreatedAtLabel.text = [wrap.createdAt stringWithFormat:@"MMMM dd, yyyy"];
	__weak typeof(self)weakSelf = self;
	[wrap contributorNames:^(NSString *names) {
		weakSelf.headerWrapAuthorsLabel.text = names;
	}];
	self.headerView.height = [wrap.candies count] > 2 ? 212 : 106;
	self.tableView.tableHeaderView = self.headerView;
	[self.topWrapStreamView reloadData];
}

- (IBAction)typeMessage:(UIButton *)sender {
	[self.composeContainer setEditing:!self.composeContainer.editing animated:YES];
}

- (void)sendMessageWithText:(NSString*)text {
	WLConversation* conversation = [WLConversation entry];
	WLComment *comment = [WLComment entry];
	comment.text = text;
	[conversation addComment:comment];
	[self.topWrap addCandy:conversation];
	[self updateHeaderViewWithWrap:self.topWrap];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue isWrapSegue]) {
		WLWrap* wrap = [self.wraps objectAtIndex:[self.tableView indexPathForSelectedRow].row];
		[(WLWrapViewController* )segue.destinationViewController setWrap:wrap];
	} else if ([segue isTopWrapSegue]) {
		[(WLWrapViewController* )segue.destinationViewController setWrap:self.topWrap];
	} else if ([segue isCameraSegue]) {
		WLCameraViewController* cameraController = segue.destinationViewController;
		cameraController.delegate = self;
		cameraController.mode = WLCameraModeFullSize;
	}
}

#pragma mark - WLComposeBarDelegate

- (void)composeBar:(WLComposeBar *)composeBar didFinishWithText:(NSString *)text {
	[self.composeContainer setEditing:NO animated:YES];
	[self sendMessageWithText:text];
}

#pragma mark - <UITableViewDataSource, UITableViewDelegate>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.wraps count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString* wrapCellIdentifier = @"WLWrapCell";
	WLWrapCell* cell = [tableView dequeueReusableCellWithIdentifier:wrapCellIdentifier
													   forIndexPath:indexPath];
	cell.item = [self.wraps objectAtIndex:(indexPath.row)];
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 44;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	return [tableView dequeueReusableCellWithIdentifier:@"LabelCell"];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	if (self.composeContainer.editing) {
		[self.composeContainer setEditing:NO animated:YES];
	}
}

#pragma mark - <WLCameraViewControllerDelegate>

- (void)cameraViewController:(WLCameraViewController *)controller didFinishWithImage:(UIImage *)image {

	WLImage* candy = [WLImage entry];
	candy.url.large = @"http://placeimg.com/135/122/any";
	candy.url.thumbnail = @"http://placeimg.com/123/124/any";
	[self.topWrap addCandy:candy];

	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraViewControllerDidCancel:(WLCameraViewController *)controller {
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - StreamViewDelegate

- (NSInteger)streamViewNumberOfColumns:(StreamView *)streamView {
	return 3;
}

- (NSInteger)streamView:(StreamView*)streamView numberOfItemsInSection:(NSInteger)section {
	if ([self.topWrap.candies count] > 2) {
		return 5;
	} else {
		return 2;
	}
}

- (UIView*)streamView:(StreamView*)streamView viewForItem:(StreamLayoutItem*)item {
	if (item.index.row < [self.topWrap.candies count]) {
		UIImageView* imageView = [streamView reusableViewOfClass:[UIImageView class] forItem:item];
		imageView.contentMode = UIViewContentModeScaleAspectFill;
		imageView.clipsToBounds = YES;
		WLCandy* candy = [self.topWrap.candies objectAtIndex:item.index.row];
		imageView.imageUrl = candy.cover.large;
		return imageView;
	} else {
		UILabel* placeholderLabel = [streamView reusableViewOfClass:[UILabel class] forItem:item];
		placeholderLabel.backgroundColor = [UIColor WL_grayColor];
		return placeholderLabel;
	}
}

- (CGFloat)streamView:(StreamView*)streamView ratioForItemAtIndex:(StreamIndex)index {
	return 1;
}

- (CGFloat)streamView:(StreamView *)streamView initialRangeForColumn:(NSInteger)column {
	return column == 1 ? 106 : 0;
}

- (void)streamView:(StreamView *)streamView didSelectItem:(StreamLayoutItem *)item {
	if (item.index.row < [self.topWrap.candies count]) {
		WLWrapDataViewController* controller = [self.storyboard wrapDataViewController];
		controller.candy = [self.topWrap.candies objectAtIndex:item.index.row];
		[self.navigationController pushViewController:controller animated:YES];
	}
}

@end
