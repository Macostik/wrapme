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
#import "WLAddressBook.h"
#import "WLInviteeCell.h"
#import "WLWrapEditSession.h"
#import "WLToast.h"
#import "WLContributor.h"
#import "WLPerson.h"

@interface WLCreateWrapViewController () <UITableViewDataSource, UITableViewDelegate, WLContributorCellDelegate, WLInviteeCellDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet WLBorderView *nameBorderView;
@property (weak, nonatomic) IBOutlet UIView *coverButtonView;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UITableView *contributorsTableView;
@property (nonatomic) BOOL editing;
@property (weak, nonatomic) IBOutlet WLImageView *imageView;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (strong, nonatomic) WLWrapEditSession *editSession;

@property (strong, nonatomic) NSMutableOrderedSet *existingContributors;

@property (strong, nonatomic) NSMutableOrderedSet *addedContributors;
@property (weak, nonatomic) IBOutlet UIButton *createButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@end

@implementation WLCreateWrapViewController

@synthesize wrap = _wrap;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.editSession = [[WLWrapEditSession alloc] initWithEntry:self.wrap];
	
	self.stillPictureCameraPosition = AVCaptureDevicePositionBack;
	self.stillPictureMode = WLCameraModeCover;
    [self verifyStartAndDoneButton];
	if (self.editing) {
        self.imageView.image = nil;
		[self configureWrapEditing];
	} else {
        self.imageView.url = [[self.pictures lastObject] medium];
        [self.nameField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.0f];
    }
	[self setTranslucent];
    [self.view insertSubview:self.translucentView aboveSubview:self.imageView];
    self.translucentView.alpha = 0.9f;
    self.translucentView.tintColor = [UIColor WL_orangeColor];
    self.createButton.superview.layer.borderColor = [UIColor WL_orangeColor].CGColor;
    self.createButton.superview.layer.borderWidth = 1;
    self.createButton.layer.borderColor = [UIColor WL_orangeColor].CGColor;
    self.createButton.layer.borderWidth = 1;
    self.backButton.layer.borderColor = [UIColor WL_orangeColor].CGColor;
    self.backButton.layer.borderWidth = 1;
}

//- (WLWrap *)wrap {
//	if (!_wrap) {
//		_wrap = [WLWrap wrap];
//	}
//	return _wrap;
//}

- (void)setWrap:(WLWrap *)wrap {
    _wrap = wrap;
    self.editing = YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	[super prepareForSegue:segue sender:sender];
	if ([segue isContributorsSegue]) {
		WLContributorsViewController* controller = segue.destinationViewController;
        controller.contributors = self.editSession.contributors;
        controller.invitees = self.editSession.invitees;
        __weak typeof(self)weakSelf = self;
        [controller setContactsBlock:^(NSArray *invitees) {
            if (!weakSelf.editSession.invitees.nonempty) {
                weakSelf.editSession.invitees = @[].mutableCopy;
            }
            [weakSelf.editSession addObjectToInvitees:invitees];
        }];
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
	[self isAtObjectSessionChanged];
}

- (void)configureWrapEditing {
	self.nameField.text = self.wrap.name;
    NSString* url = [self.wrap.picture anyUrl];
    self.imageView.url = url;
    if (!url) {
        self.imageView.image = [UIImage imageNamed:@"default-medium-cover"];
    }
	self.startButton.hidden = YES;
	self.doneButton.hidden = NO;
	self.cancelButton.hidden = NO;
	self.titleLabel.text = @"Edit wrap";
	if (![self.wrap.contributor isCurrentUser]) {
		self.coverButtonView.hidden = YES;
		self.imageView.height = self.imageView.width;
		self.nameField.userInteractionEnabled = NO;
		self.nameBorderView.strokeColor = [UIColor clearColor];
	}
}

- (void)verifyStartAndDoneButton {
	BOOL enabled = self.editSession.name.nonempty;
	self.startButton.active = enabled;
	self.doneButton.active = enabled;
	self.cancelButton.active = enabled;
}

#pragma mark - Actions

- (IBAction)back:(id)sender {
    if (!self.editing) {
        [self.wrap remove];
    }
	[self dismiss];
}

- (IBAction)start:(id)sender {
	[self.spinner startAnimating];
	__weak typeof(self)weakSelf = self;
	[self lock];
    WLWrap* wrap = [WLWrap wrap];
    [self.editSession apply:wrap];
	[wrap save];
    [wrap broadcastCreation];
    void (^completion) (WLWrap*) = ^ (WLWrap* wrap) {
        WLWrapViewController* wrapController = [WLWrapViewController instantiate];
		wrapController.wrap = wrap;
		[UINavigationController pushViewController:wrapController animated:YES];
		[weakSelf dismiss:WLWrapTransitionFromLeft];
    };
    
    [[WLUploading uploading:wrap] upload:^(id object) {
        [weakSelf.spinner stopAnimating];
        [weakSelf unlock];
        wrap.invitees = nil;
		completion(object);
    } failure:^(NSError *error) {
        [weakSelf.spinner stopAnimating];
		[weakSelf unlock];
        if ([error isNetworkError]) {
            completion(wrap);
        } else {
            [error show];
            [[WLEntryManager manager].context refreshObject:self.wrap mergeChanges:NO];
        }
    }];
}

- (IBAction)cancel:(id)sender {
    [self.delegate createWrapViewControllerDidCancel:self];
}

- (IBAction)done:(id)sender {
    NSString* name = self.nameField.text;
    if (name.nonempty) {
        [self.spinner startAnimating];
        __weak typeof(self)weakSelf = self;
        [self lock];
        WLWrap* wrap = [WLWrap wrap];
        wrap.name = name;
        [wrap save];
        [wrap broadcastCreation];
        [[WLUploading uploading:wrap] upload:^(id object) {
            [weakSelf.spinner stopAnimating];
            [weakSelf unlock];
            [weakSelf.delegate createWrapViewController:weakSelf didCreateWrap:wrap];
            [wrap uploadPictures:weakSelf.pictures];
        } failure:^(NSError *error) {
            [weakSelf.spinner stopAnimating];
            [weakSelf unlock];
            if ([error isNetworkError]) {
                [weakSelf.delegate createWrapViewController:weakSelf didCreateWrap:wrap];
                [wrap uploadPictures:weakSelf.pictures];
            } else {
                [error show];
                [wrap remove];
            }
        }];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 1 ? [self.editSession.contributors count] : [self.editSession.invitees count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        WLContributorCell* cell = [tableView dequeueReusableCellWithIdentifier:[WLContributorCell reuseIdentifier]];
        WLUser* contributor = self.editSession.contributors[indexPath.row];
        cell.item = contributor;
        if (!self.wrap || [self.wrap.contributor isCurrentUser]) {
            cell.deletable = [contributor isCurrentUser];
        } else {
            cell.deletable = [self.wrap.contributors containsObject:contributor];
        }
        return cell;
    } else {
        WLInviteeCell *cell = [tableView dequeueReusableCellWithIdentifier:[WLInviteeCell reuseIdentifier]];
        WLPerson *person = self.editSession.invitees[indexPath.row];
        cell.item = person;
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return section && [self.editSession.invitees count] ? 5.0f : .0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if ([self.editSession.invitees count] && section) {
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor WL_orangeColor];
        return view;
    }
    return nil;
}

#pragma mark - UITextFieldDelegate

- (IBAction)textFieldDidChange:(UITextField *)sender {
	if (sender.text.length > WLWrapNameLimit) {
		sender.text = [sender.text substringToIndex:WLWrapNameLimit];
	}
	self.editSession.name = sender.text;
    self.createButton.enabled = sender.text.nonempty;
	[self verifyStartAndDoneButton];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	if (![self.editSession.name isEqualToString:self.nameField.text]) {
        self.editSession.name = self.nameField.text;
	}
	[self isAtObjectSessionChanged];
}

#pragma mark - WLContributorCellDelegate

- (void)contributorCell:(WLContributorCell *)cell didRemoveContributor:(WLUser *)contributor {
	[self.editSession.contributors removeObject:contributor];
	[self refreshContributorsTableView];
}

- (BOOL)contributorCell:(WLContributorCell *)cell isCreator:(WLUser *)contributor {
    return !self.wrap || [self.wrap.contributor isEqualToEntry:contributor];
}

#pragma mark - WLInviteeCellDelegate

- (void)inviteeCell:(WLInviteeCell *)cell didRemovePerson:(WLPerson *)person {
    self.editSession.invitees = (id)[self.editSession.invitees arrayByRemovingObject:person];
    [self refreshContributorsTableView];
}


#pragma mark Override base method

- (void)updateIfNeeded:(void (^)(void))completion {
	if ([self isAtObjectSessionChanged]) {
        
		if (![self.editSession hasChanges]) {
			[WLToast showWithMessage:@"Your name isn't correct."];
            return;
		}
        if (self.wrap.uploading.operation != nil) {
			[WLToast showWithMessage:@"Wrap is uploading, wait a moment..."];
            return;
		}
        [super updateIfNeeded:completion];
        __weak typeof(self)weakSelf = self;
        [self.editSession apply:self.wrap];
        [self.wrap update:^(WLWrap *wrap) {
            [weakSelf.spinner stopAnimating];
            [weakSelf dismiss];
            weakSelf.wrap.invitees = nil;
            [weakSelf unlock];
        } failure:^(NSError *error) {
            if ([error isNetworkError] && weakSelf.wrap.uploading) {
                [weakSelf.wrap broadcastChange];
                [weakSelf dismiss];
            } else {
                [error show];
                [weakSelf.editSession reset:weakSelf.wrap];
            }
            [weakSelf.spinner stopAnimating];
            [weakSelf unlock];
        }];
		
	} else {
		completion();
	}
}

- (void)validateDoneButton {
    self.doneButton.active = self.nameField.text.nonempty;
}

- (void)saveImage:(UIImage *)image {
	__weak typeof(self)weakSelf = self;
	[[WLImageCache cache] setImage:image completion:^(NSString *path) {
		weakSelf.editSession.url = path;
		weakSelf.imageView.url = path;
		[weakSelf isAtObjectSessionChanged];
	}];
}

@end
