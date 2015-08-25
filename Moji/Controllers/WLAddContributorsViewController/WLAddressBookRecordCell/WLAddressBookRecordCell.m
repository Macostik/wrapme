//
//  WLContactCell.m
//  moji
//
//  Created by Ravenpod on 09.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAddressBookRecordCell.h"
#import "WLAddressBook.h"
#import "WLAddressBookPhoneNumberCell.h"
#import "WLAddressBookPhoneNumber.h"
#import "UIView+QuartzCoreHelper.h"

@interface WLAddressBookRecordCell () <UITableViewDataSource, UITableViewDelegate, WLAddressBookPhoneNumberCellDelegate>

@property (weak, nonatomic) IBOutlet UIButton *selectButton;
@property (nonatomic, weak) IBOutlet UITableView* tableView;
@property (nonatomic, weak) IBOutlet UILabel* nameLabel;
@property (nonatomic, weak) IBOutlet WLImageView* avatarView;
@property (weak, nonatomic) IBOutlet UIButton *openView;
@property (weak, nonatomic) IBOutlet UILabel *signUpView;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;

@end

@implementation WLAddressBookRecordCell

- (void)awakeFromNib {
	[super awakeFromNib];
	self.avatarView.circled = YES;
    
    self.signUpView.layer.borderWidth = 1;
    self.signUpView.layer.borderColor = self.signUpView.textColor.CGColor;
}

+ (instancetype)cellWithContact:(WLAddressBookRecord *)record inTableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
	WLAddressBookRecordCell* cell = nil;
	if ([record.phoneNumbers count] > 1) {
		cell = [tableView dequeueReusableCellWithIdentifier:@"WLMultipleAddressBookRecordCell" forIndexPath:indexPath];
	} else {
		cell = [tableView dequeueReusableCellWithIdentifier:@"WLAddressBookRecordCell" forIndexPath:indexPath];
	}
	cell.record = record;
	return cell;
}

- (void)setRecord:(WLAddressBookRecord *)record {
    _record = record;
	WLAddressBookPhoneNumber* phoneNumber = [record.phoneNumbers lastObject];
    
    self.signUpView.hidden = (phoneNumber.user && phoneNumber.activated) ? NO : YES;
	self.nameLabel.text = [phoneNumber priorityName];
    NSString *url = phoneNumber.priorityPicture.small;
    if (self.signUpView && !self.signUpView.hidden && !url.nonempty) {
        self.avatarView.defaultBackgroundColor = WLColors.orange;
    } else {
        self.avatarView.defaultBackgroundColor = WLColors.grayLighter;
    }
    self.avatarView.url = url;
	
	if (self.tableView) {
		[self.tableView reloadData];
	} else {
        self.phoneLabel.text = [WLAddressBookRecordCell collectionPersonsStringFromContact:record];
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
        self.selectButton.enabled = NO;
    } else {
        self.selectButton.enabled = YES;
        self.selectButton.selected = state == WLContactCellStateSelected;
    }
}

- (void)setOpened:(BOOL)opened {
	_opened = opened;
	[UIView beginAnimations:nil context:nil];
	self.openView.selected = opened;
	[UIView commitAnimations];
}

#pragma mark - Actions

- (IBAction)select:(id)sender {
    WLAddressBookPhoneNumber *person = [self.record.phoneNumbers lastObject];
	[self.delegate contactCell:self didSelectPerson:person];
}

- (IBAction)open:(id)sender {
	self.opened = !self.opened;
	[self.delegate contactCellDidToggle:self];
}

#pragma mark - UITableViewDataSource, UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	WLAddressBookRecord* contact = self.record;
	return [contact.phoneNumbers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLAddressBookPhoneNumberCell* cell = [tableView dequeueReusableCellWithIdentifier:@"WLAddressBookPhoneNumberCell" forIndexPath:indexPath];
	WLAddressBookRecord* contact = self.record;
	cell.phoneNumber = contact.phoneNumbers[indexPath.row];
	cell.checked = [self.delegate contactCell:self phoneNumberState:cell.phoneNumber];
	return cell;
}

#pragma mark - WLAddressBookPhoneNumberCellDelegate

- (void)personCell:(WLAddressBookPhoneNumberCell *)cell didSelectPerson:(WLAddressBookPhoneNumber *)person {
	[self.delegate contactCell:self didSelectPerson:person];
}

@end
