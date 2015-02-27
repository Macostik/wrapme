//
//  WLContactCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 09.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLContactCell.h"
#import "WLAddressBook.h"
#import "WLUser.h"
#import "WLImageFetcher.h"
#import "NSString+Additions.h"
#import "WLAddressBookPhoneNumberCell.h"
#import "UIView+Shorthand.h"
#import "NSArray+Additions.h"
#import "WLAddressBookPhoneNumber.h"
#import "WLAPIManager.h"

@interface WLContactCell () <UITableViewDataSource, UITableViewDelegate, WLAddressBookPhoneNumberCellDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *selectionView;
@property (weak, nonatomic) IBOutlet UIView *addedView;
@property (nonatomic, weak) IBOutlet UITableView* tableView;
@property (nonatomic, weak) IBOutlet UILabel* nameLabel;
@property (nonatomic, weak) IBOutlet WLImageView* avatarView;
@property (weak, nonatomic) IBOutlet UIImageView *openView;
@property (weak, nonatomic) IBOutlet UIImageView *signUpView;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;

@end

@implementation WLContactCell

- (void)awakeFromNib {
	[super awakeFromNib];
	self.avatarView.circled = YES;
    [self.avatarView setImageName:@"default-medium-avatar" forState:WLImageViewStateEmpty];
    [self.avatarView setImageName:@"default-medium-avatar" forState:WLImageViewStateFailed];
}

+ (instancetype)cellWithContact:(WLAddressBookRecord *)contact inTableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
	WLContactCell* cell = nil;
	if ([contact.phoneNumbers count] > 1) {
		cell = [tableView dequeueReusableCellWithIdentifier:@"WLMultipleContactCell" forIndexPath:indexPath];
	} else {
		cell = [tableView dequeueReusableCellWithIdentifier:@"WLContactCell" forIndexPath:indexPath];
	}
	cell.item = contact;
	return cell;
}

- (void)setupItemData:(WLAddressBookRecord*)contact {
	WLAddressBookPhoneNumber* phoneNumber = [contact.phoneNumbers lastObject];
     self.avatarView.url = phoneNumber.priorityPicture.small;
    self.signUpView.hidden = (phoneNumber.user) ? NO : YES;
	self.nameLabel.text = [phoneNumber priorityName];
	
	if (self.tableView) {
		[self.tableView reloadData];
	} else {
        self.phoneLabel.text = [WLContactCell collectionPersonsStringFromContact:contact];
		self.state = [self.delegate contactCell:self phoneNumberState:phoneNumber];
	}
}

+ (NSString *)collectionPersonsStringFromContact:(WLAddressBookRecord *)contact {
    WLAddressBookPhoneNumber *person = [contact.phoneNumbers lastObject];
    if (person) {
        WLUser *user = person.user;
        if (user.valid) {
            return [user phones];
        } else {
            return [person phone];
        }
    }
    return nil;
}

- (void)setState:(WLContactCellState)state {
	_state = state;
    if (state == WLContactCellStateAdded) {
        self.addedView.hidden = NO;
        self.selectionView.hidden = YES;
    } else {
        self.addedView.hidden = YES;
        self.selectionView.hidden = NO;
        self.selectionView.highlighted = state == WLContactCellStateSelected;
    }
}

- (void)setOpened:(BOOL)opened {
	_opened = opened;
	[UIView beginAnimations:nil context:nil];
	self.openView.highlighted = opened;
	[UIView commitAnimations];
}

#pragma mark - Actions

- (IBAction)select:(id)sender {
	WLAddressBookRecord* contact = self.item;
    WLAddressBookPhoneNumber *person = [contact.phoneNumbers lastObject];
	[self.delegate contactCell:self didSelectPerson:person];
}

- (IBAction)open:(id)sender {
	self.opened = !self.opened;
	[self.delegate contactCellDidToggle:self];
}

#pragma mark - UITableViewDataSource, UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	WLAddressBookRecord* contact = self.item;
	return [contact.phoneNumbers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLAddressBookPhoneNumberCell* cell = [tableView dequeueReusableCellWithIdentifier:@"WLAddressBookPhoneNumberCell" forIndexPath:indexPath];
	WLAddressBookRecord* contact = self.item;
	cell.item = contact.phoneNumbers[indexPath.row];
	cell.checked = [self.delegate contactCell:self phoneNumberState:cell.item];
	return cell;
}

#pragma mark - WLAddressBookPhoneNumberCellDelegate

- (void)personCell:(WLAddressBookPhoneNumberCell *)cell didSelectPerson:(WLAddressBookPhoneNumber *)person {
	[self.delegate contactCell:self didSelectPerson:person];
}

@end
