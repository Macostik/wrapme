//
//  WLContributorsViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 25.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLAddContributorsViewController.h"
#import "WLAPIManager.h"
#import "WLAddressBook.h"
#import "NSArray+Additions.h"
#import "NSString+Additions.h"
#import "UIView+Shorthand.h"
#import "WLContactCell.h"
#import "UIColor+CustomColors.h"
#import "UIFont+CustomFonts.h"
#import "WLInviteViewController.h"
#import "WLEntryManager.h"
#import "WLAddressBookPhoneNumber.h"
#import "WLContributorsRequest.h"
#import "WLButton.h"
#import "WLEntryNotifier.h"
#import "WLUpdateContributorsRequest.h"
#import "WLFontPresetter.h"
#import "WLArrangedAddressBook.h"
#import "WLAddressBookGroupView.h"
#import "NSObject+NibAdditions.h"

@interface WLAddContributorsViewController () <UITableViewDataSource, UITableViewDelegate, WLContactCellDelegate, UITextFieldDelegate, WLInviteViewControllerDelegate, WLFontPresetterReceiver>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *searchField;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, strong) NSMutableSet* openedRows;

@property (strong, nonatomic) WLArrangedAddressBook* addressBook;

@property (strong, nonatomic) WLArrangedAddressBook* filteredAddressBook;

@end

@implementation WLAddContributorsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.openedRows = [NSMutableSet set];
    self.addressBook = [[WLArrangedAddressBook alloc] initWithWrap:self.wrap];
    [self.spinner startAnimating];
	__weak typeof(self)weakSelf = self;
    [[WLContributorsRequest request] send:^(id object) {
        [weakSelf.addressBook addRecords:object];
        [weakSelf filterContacts];
		[weakSelf.spinner stopAnimating];
    } failure:^(NSError *error) {
        [weakSelf.spinner stopAnimating];
		[error show];
    }];
    [[WLFontPresetter presetter] addReceiver:self];
}

- (void)filterContacts {
    self.filteredAddressBook  = [self.addressBook filteredAddressBookWithText:self.searchField.text];
    [self.tableView reloadData];
}

#pragma mark - Actions

- (IBAction)done:(WLButton*)sender {
    if (self.addressBook.selectedPhoneNumbers.count == 0) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    WLUpdateContributorsRequest *updateConributors = [WLUpdateContributorsRequest request:self.wrap];
    updateConributors.contributors = self.addressBook.selectedPhoneNumbers;
    updateConributors.isAddContirbutor = YES;
    sender.loading = YES;
    self.view.userInteractionEnabled = NO;
    __weak typeof(self)weakSelf = self;
    [updateConributors send:^(id object) {
        [weakSelf.navigationController popViewControllerAnimated:YES];
    } failure:^(NSError *error) {
        sender.loading = NO;
        [error show];
        weakSelf.view.userInteractionEnabled = YES;
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [self.filteredAddressBook.groups count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    WLArrangedAddressBookGroup *group = self.filteredAddressBook.groups[section];
	return [group.records count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WLArrangedAddressBookGroup *group = self.filteredAddressBook.groups[indexPath.section];
    WLAddressBookRecord* contact = group.records[indexPath.row];
    WLContactCell* cell = [WLContactCell cellWithContact:contact inTableView:tableView indexPath:indexPath];
	cell.opened = ([contact.phoneNumbers count] > 1 && [self.openedRows containsObject:contact]);
    
    if ([tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        cell.preservesSuperviewLayoutMargins = NO;
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    WLArrangedAddressBookGroup *group = self.filteredAddressBook.groups[indexPath.section];
	WLAddressBookRecord* contact = group.records[indexPath.row];
    return [self heightForRowWithContact:contact];
}

const static CGFloat WLIndent = 32.0f;
const static CGFloat WLDefaultHeight = 50.0f;

- (CGFloat)heightForRowWithContact:(WLAddressBookRecord *)contact {
    if ([contact.phoneNumbers count] > 1) {
        if ([self.openedRows containsObject:contact]) {
            return WLDefaultHeight + [contact.phoneNumbers count] * WLDefaultHeight;
        } else {
            return WLDefaultHeight;
        }
    } else {
        NSString *phoneString = [WLContactCell collectionPersonsStringFromContact:contact];
        CGFloat height = [phoneString heightWithFont:[UIFont fontWithName:WLFontOpenSansLight preset:WLFontPresetSmaller]
                                       width:self.tableView.width - 120.0f];
        return MAX(WLDefaultHeight, height + WLIndent);
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    WLArrangedAddressBookGroup *group = self.filteredAddressBook.groups[section];
    return group.title.nonempty && group.records.nonempty ? 32 : 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    WLArrangedAddressBookGroup *group = self.filteredAddressBook.groups[section];
    if (group.title.nonempty && group.records.nonempty) {
        WLAddressBookGroupView *header = [WLAddressBookGroupView loadFromNib];
        header.group = group;
        return header;
    }
    return nil;
}

#pragma mark - WLContactCellDelegate

- (WLContactCellState)contactCell:(WLContactCell *)cell phoneNumberState:(WLAddressBookPhoneNumber *)phoneNumber {
    if ([self.wrap.contributors containsObject:phoneNumber.user]) {
        return WLContactCellStateAdded;
    }
    return [self.addressBook selectedPhoneNumber:phoneNumber] != nil ? WLContactCellStateSelected : WLContactCellStateDefault;
}

- (void)contactCell:(WLContactCell *)cell didSelectPerson:(WLAddressBookPhoneNumber *)person {
    
    [self.addressBook selectPhoneNumber:person];
	
	NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
	if (indexPath) {
		[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
	}
}

- (void)contactCellDidToggle:(WLContactCell *)cell {
	if ([self.openedRows containsObject:cell.item]) {
		[self.openedRows removeObject:cell.item];
	} else {
		[self.openedRows addObject:cell.item];
	}
	[self.tableView beginUpdates];
	[self.tableView endUpdates];
}

#pragma mark - UITextFieldDelegate

- (IBAction)searchTextChanged:(UITextField *)sender {
    [self filterContacts];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self filterContacts];
	[textField resignFirstResponder];
	return YES;
}

#pragma mark - WLInviteViewControllerDelegate

- (NSError *)inviteViewController:(WLInviteViewController *)controller didInviteContact:(WLAddressBookRecord *)contact {
    __weak typeof(self)weakSelf = self;
    return [self.addressBook addUniqueRecord:contact completion:^(WLAddressBookRecord *record, WLArrangedAddressBookGroup *group) {
        [weakSelf.addressBook selectPhoneNumber:[record.phoneNumbers firstObject]];
        [weakSelf filterContacts];
        NSUInteger section = [weakSelf.addressBook.groups indexOfObject:group];
        NSUInteger row = [group.records indexOfObject:record];
        if (row != NSNotFound && section != NSNotFound) {
            [weakSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]
                                  atScrollPosition:UITableViewScrollPositionMiddle
                                          animated:YES];
        }
    }];
}

#pragma mark - WLFontPresetterReceiver

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter *)presetter {
    [self.tableView reloadData];
}

@end
