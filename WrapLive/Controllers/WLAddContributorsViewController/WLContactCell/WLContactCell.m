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
#import "WLPersonCell.h"
#import "UIView+Shorthand.h"
#import "NSArray+Additions.h"
#import "WLPerson.h"

@interface WLContactCell () <UITableViewDataSource, UITableViewDelegate, WLPersonCellDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *selectionView;
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
}

+ (instancetype)cellWithContact:(WLContact *)contact inTableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
	WLContactCell* cell = nil;
	if ([contact.persons count] > 1) {
		cell = [tableView dequeueReusableCellWithIdentifier:@"WLMultipleContactCell" forIndexPath:indexPath];
	} else {
		cell = [tableView dequeueReusableCellWithIdentifier:@"WLContactCell" forIndexPath:indexPath];
	}
	cell.item = contact;
	return cell;
}

- (void)setupItemData:(WLContact*)contact {
	WLPerson* person = [contact.persons lastObject];
     self.avatarView.url = person.priorityPicture.small;
    if (!self.avatarView.url.nonempty) {
        self.avatarView.image = [UIImage imageNamed:@"default-medium-avatar"];
    }
    self.signUpView.hidden = (person.user) ? NO : YES;
	self.nameLabel.text = [person priorityName];
	
	if (self.tableView) {
		[self.tableView reloadData];
	} else {
        self.phoneLabel.text = [WLContactCell collectionPersonsStringFromContact:contact];
		self.checked = [self personSelected:person];
	}
}

+ (NSString *)collectionPersonsStringFromContact:(WLContact *)contact {
    __block NSMutableString *phoneString = [NSMutableString string];
    NSArray *userArray = [contact.persons valueForKey:@"user"];
    if (userArray.nonempty) {
        [userArray all:^(id item) {
            if ([item isKindOfClass:[WLUser class]]) {
                NSArray *phoneArray = [[[item devices] array] valueForKey:@"phone"];
                [phoneString appendString:[phoneArray componentsJoinedByString:@"\n"]];
            } else {
                WLPerson *person = [contact.persons lastObject];
                [phoneString appendString:WLString([person phone])];
            }
        }];
    }
    return phoneString;
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

- (BOOL)personSelected:(WLPerson*)person {
	return [self.delegate contactCell:self personSelected:person];
}

#pragma mark - Actions

- (IBAction)select:(id)sender {
	WLContact* contact = self.item;
    WLPerson *person = [contact.persons lastObject];
	[self.delegate contactCell:self didSelectPerson:person];
}

- (IBAction)open:(id)sender {
	self.opened = !self.opened;
	[self.delegate contactCellDidToggle:self];
}

#pragma mark - UITableViewDataSource, UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	WLContact* contact = self.item;
	return [contact.persons count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLPersonCell* cell = [tableView dequeueReusableCellWithIdentifier:@"WLPersonCell" forIndexPath:indexPath];
	WLContact* contact = self.item;
	cell.item = contact.persons[indexPath.row];
	cell.checked = [self personSelected:cell.item];
	return cell;
}

#pragma mark - WLPersonCellDelegate

- (void)personCell:(WLPersonCell *)cell didSelectPerson:(WLPerson *)person {
	[self.delegate contactCell:self didSelectPerson:person];
}

@end
