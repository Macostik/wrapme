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
#import "UIImageView+ImageLoading.h"
#import "NSString+Additions.h"
#import "WLPhoneCell.h"
#import "UIView+Shorthand.h"

@interface WLContactCell () <UITableViewDataSource, UITableViewDelegate, WLPhoneCellDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *selectionView;
@property (nonatomic, weak) IBOutlet UITableView* tableView;
@property (nonatomic, weak) IBOutlet UILabel* nameLabel;
@property (nonatomic, weak) IBOutlet UIImageView* avatarView;
@property (weak, nonatomic) IBOutlet UIImageView *openView;

@end

@implementation WLContactCell

- (void)awakeFromNib {
	[super awakeFromNib];
	self.avatarView.circled = YES;
}

+ (instancetype)cellWithContact:(WLContact *)contact inTableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
	WLContactCell* cell = nil;
	if ([contact.users count] > 1) {
		cell = [tableView dequeueReusableCellWithIdentifier:@"WLMultipleContactCell" forIndexPath:indexPath];
	} else {
		cell = [tableView dequeueReusableCellWithIdentifier:@"WLContactCell" forIndexPath:indexPath];
	}
	cell.item = contact;
	return cell;
}

- (void)setupItemData:(WLContact*)contact {
	WLUser* user = [contact.users lastObject];
	self.nameLabel.text = user.name;
	if (user.picture.medium.nonempty) {
		self.avatarView.imageUrl = user.picture.medium;
	} else {
		self.avatarView.image = [UIImage imageNamed:@"ic_default_profile"];
	}
	self.checked = [self contributorSelected:user];
	
	if (self.tableView) {
		[self.tableView reloadData];
	}
}

- (void)setChecked:(BOOL)checked {
	_checked = checked;
	[UIView beginAnimations:nil context:nil];
	self.selectionView.highlighted = checked;
	[UIView commitAnimations];
}

- (void)setOpened:(BOOL)opened {
	_opened = opened;
	[UIView beginAnimations:nil context:nil];
	self.openView.highlighted = opened;
	[UIView commitAnimations];
}

- (BOOL)contributorSelected:(WLUser*)contributor {
	return [self.delegate contactCell:self contributorSelected:contributor];
}

#pragma mark - Actions

- (IBAction)select:(id)sender {
	WLContact* contact = self.item;
	[self.delegate contactCell:self didSelectContributor:[contact.users lastObject]];
}

- (IBAction)open:(id)sender {
	self.opened = !self.opened;
	[self.delegate contactCellDidToggle:self];
}

#pragma mark - UITableViewDataSource, UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	WLContact* contact = self.item;
	return [contact.users count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLPhoneCell* cell = [tableView dequeueReusableCellWithIdentifier:@"WLPhoneCell" forIndexPath:indexPath];
	WLContact* contact = self.item;
	cell.item = contact.users[indexPath.row];
	cell.checked = [self contributorSelected:cell.item];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	WLContact* contact = self.item;
	[self.delegate contactCell:self didSelectContributor:contact.users[indexPath.row]];
}

#pragma mark - WLSelectContributorCellDelegate

- (void)phoneCell:(WLPhoneCell *)cell didSelectContributor:(WLUser *)contributor {
	[self.delegate contactCell:self didSelectContributor:contributor];
}

@end
