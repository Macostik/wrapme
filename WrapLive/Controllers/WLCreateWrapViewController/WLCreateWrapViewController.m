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
#import "WLStillPictureViewController.h"
#import "WLAddressBook.h"
#import "WLInviteeCell.h"

@interface WLCreateWrapViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, WLContributorCellDelegate, WLInviteeCellDelegate, WLStillPictureViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet WLBorderView *nameBorderView;
@property (weak, nonatomic) IBOutlet UIView *coverButtonView;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UITableView *contributorsTableView;
@property (strong, nonatomic) IBOutlet UIView *noContributorsView;
@property (nonatomic) BOOL editing;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property (strong, nonatomic) NSOrderedSet *existingContributors;

@end

@implementation WLCreateWrapViewController

@synthesize wrap = _wrap;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[WLEntryManager manager] lock];
	[self verifyStartAndDoneButton];
	if (self.editing) {
        self.coverView.image = nil;
		[self configureWrapEditing];
	}
	[self setTranslucent];
}

- (WLWrap *)wrap {
	if (!_wrap) {
		_wrap = [WLWrap wrap];
	}
	return _wrap;
}

- (void)setWrap:(WLWrap *)wrap {
    _wrap = wrap;
    self.editing = YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue isContributorsSegue]) {
		WLContributorsViewController* controller = segue.destinationViewController;
		controller.wrap = self.wrap;
	} else if ([segue isCameraSegue]) {
		WLStillPictureViewController* controller = segue.destinationViewController;
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
	self.contributorsTableView.tableFooterView = self.wrap.contributors.nonempty ? nil : self.noContributorsView;
}

- (void)configureWrapEditing {
	self.nameField.text = self.wrap.name;
    NSString* url = [self.wrap.picture anyUrl];
    self.coverView.url = url;
    if (!url) {
        self.coverView.image = [UIImage imageNamed:@"default-medium-cover"];
    }
	self.startButton.hidden = YES;
	self.doneButton.hidden = NO;
	self.titleLabel.text = @"Edit wrap";
    self.existingContributors = self.wrap.contributors;
	if (![self.wrap.contributor isCurrentUser]) {
		self.coverButtonView.hidden = YES;
		self.coverView.height = self.coverView.width;
		self.nameField.userInteractionEnabled = NO;
		self.nameBorderView.strokeColor = [UIColor clearColor];
	}
}

- (void)verifyStartAndDoneButton {
	BOOL enabled = self.wrap.name.nonempty;
	self.startButton.active = enabled;
	self.doneButton.active = enabled;
}

#pragma mark - Actions

- (IBAction)back:(id)sender {
    if (self.editing) {
        [[WLEntryManager manager].context refreshObject:self.wrap mergeChanges:NO];
//        [WLUser currentUser].name;
    } else {
        [self.wrap remove];
    }
    [[WLEntryManager manager] unlock];
	[self dismiss];
}

- (IBAction)done:(UIButton *)sender {
	if ([self.wrap hasChanges]) {
		[self lock];
		[self.spinner startAnimating];
		__weak typeof(self)weakSelf = self;
		[self.wrap update:^(WLWrap *wrap) {
            [[WLEntryManager manager] unlock];
			[weakSelf.spinner stopAnimating];
			[weakSelf dismiss];
            weakSelf.wrap.invitees = nil;
			[weakSelf unlock];
		} failure:^(NSError *error) {
            if ([error isNetworkError] && weakSelf.wrap.uploading) {
                [[WLEntryManager manager] unlock];
                [weakSelf.wrap broadcastChange];
                [weakSelf dismiss];
            } else {
                [error show];
            }
			[weakSelf.spinner stopAnimating];
			[weakSelf unlock];
		}];
	} else {
        [[WLEntryManager manager] unlock];
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
	[self.wrap save];
    [self.wrap broadcastCreation];
    void (^completion) (WLWrap*) = ^ (WLWrap* wrap) {
        [[WLEntryManager manager] unlock];
        WLWrapViewController* wrapController = [WLWrapViewController instantiate];
		wrapController.wrap = wrap;
		[UINavigationController pushViewController:wrapController animated:YES];
		[weakSelf dismiss:WLWrapTransitionFromLeft];
    };
    
    [[WLUploading uploading:self.wrap] upload:^(id object) {
        [weakSelf.spinner stopAnimating];
        [weakSelf unlock];
        weakSelf.wrap.invitees = nil;
		completion(object);
    } failure:^(NSError *error) {
        [weakSelf.spinner stopAnimating];
		[weakSelf unlock];
        if ([error isNetworkError]) {
            completion(weakSelf.wrap);
        } else {
            [error show];
        }
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return section == 0 ? [self.wrap.contributors count] : [self.wrap.invitees count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        WLContributorCell* cell = [tableView dequeueReusableCellWithIdentifier:[WLContributorCell reuseIdentifier]];
        WLUser* contributor = self.wrap.contributors[indexPath.row];
        cell.item = contributor;
        if ([self.wrap.contributor isCurrentUser]) {
            cell.deletable = ![contributor isCurrentUser];
        } else {
            cell.deletable = ![self.existingContributors containsObject:contributor];
        }
        return cell;
    } else {
        WLInviteeCell *cell = [tableView dequeueReusableCellWithIdentifier:[WLInviteeCell reuseIdentifier]];
        WLPhone *phone = self.wrap.invitees[indexPath.row];
        cell.item = phone;
        return cell;
    }
}

#pragma mark - UITextFieldDelegate

- (IBAction)textFieldDidChange:(UITextField *)sender {
	if (sender.text.length > WLWrapNameLimit) {
		sender.text = [sender.text substringToIndex:WLWrapNameLimit];
	}
	self.wrap.name = sender.text;
	[self verifyStartAndDoneButton];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

#pragma mark - WLContributorCellDelegate

- (void)contributorCell:(WLContributorCell *)cell didRemoveContributor:(WLUser *)contributor {
	self.wrap.contributors = (id)[self.wrap.contributors orderedSetByRemovingObject:contributor];
	[self refreshContributorsTableView];
}

- (BOOL)contributorCell:(WLContributorCell *)cell isCreator:(WLUser *)contributor {
    return [self.wrap.contributor isEqualToEntry:contributor];
}

#pragma mark - WLInviteeCellDelegate

- (void)inviteeCell:(WLInviteeCell *)cell didRemovePhone:(WLPhone *)phone {
    self.wrap.invitees = (id)[self.wrap.invitees arrayByRemovingObject:phone];
    [self refreshContributorsTableView];
}

#pragma mark - WLStillPictureViewControllerDelegate

- (void)stillPictureViewController:(WLStillPictureViewController *)controller didFinishWithImage:(UIImage *)image {
	self.coverView.image = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill
                                                       bounds:self.coverView.retinaSize
                                         interpolationQuality:kCGInterpolationDefault];
	__weak typeof(self)weakSelf = self;
	[[WLImageCache cache] setImage:image completion:^(NSString *path) {
        weakSelf.wrap.picture = [[WLPicture alloc] init];
		weakSelf.wrap.picture.large = path;
	}];
	
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)stillPictureViewControllerDidCancel:(WLStillPictureViewController *)controller {
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
