//
//  WLContributorsViewController.m
//  moji
//
//  Created by Ravenpod on 25.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAddContributorsViewController.h"
#import "WLAddressBook.h"
#import "WLAddressBookRecordCell.h"
#import "UIFont+CustomFonts.h"
#import "WLInviteViewController.h"
#import "WLAddressBookPhoneNumber.h"
#import "WLButton.h"
#import "WLFontPresetter.h"
#import "WLArrangedAddressBook.h"
#import "WLAddressBookGroupView.h"
#import "NSObject+NibAdditions.h"

@interface WLAddContributorsViewController () <UITableViewDataSource, UITableViewDelegate, WLContactCellDelegate, UITextFieldDelegate, WLInviteViewControllerDelegate, WLFontPresetterReceiver, WLAddressBookReceiver>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *searchField;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, strong) NSMutableArray* openedRows;

@property (strong, nonatomic) WLArrangedAddressBook* addressBook;

@property (strong, nonatomic) WLArrangedAddressBook* filteredAddressBook;

@property (strong, nonatomic) NSMutableSet* invitedRecords;

@end

@implementation WLAddContributorsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.invitedRecords = [NSMutableSet set];
    self.openedRows = [NSMutableArray array];
    [self.spinner startAnimating];
	__weak typeof(self)weakSelf = self;
    BOOL cached = [[WLAddressBook addressBook] cachedRecords:^(NSArray *array) {
        [weakSelf addressBook:[WLAddressBook addressBook] didUpdateCachedRecords:array];
        [weakSelf.spinner stopAnimating];
    } failure:^(NSError *error) {
        [weakSelf.spinner stopAnimating];
        [error show];
    }];
    [[WLAddressBook addressBook] addReceiver:self];
    if (cached) {
        [[WLAddressBook addressBook] updateCachedRecords];
    }
    [[WLFontPresetter presetter] addReceiver:self];
}

- (void)filterContacts {
    self.filteredAddressBook  = [self.addressBook filteredAddressBookWithText:self.searchField.text];
    [self.tableView reloadData];
}

// MARK: - WLAddressBookReceiver

- (void)addressBook:(WLAddressBook *)addressBook didUpdateCachedRecords:(NSArray *)cachedRecords {
    [self.spinner stopAnimating];
    WLArrangedAddressBook *oldAddressBook = self.addressBook;
    self.addressBook = [[WLArrangedAddressBook alloc] initWithWrap:self.wrap];
    [self.addressBook addRecords:cachedRecords];
    for (WLAddressBookRecord *record in self.invitedRecords) {
        [self.addressBook addUniqueRecord:record success:nil failure:nil];
    }
    if (oldAddressBook != nil) {
        self.addressBook.selectedPhoneNumbers = [oldAddressBook.selectedPhoneNumbers map:^id (WLAddressBookPhoneNumber *phoneNumber) {
            return [self.addressBook phoneNumberIdenticalTo:phoneNumber];
        }];
    }
    
    [self filterContacts];
}

#pragma mark - Actions

- (IBAction)done:(WLButton*)sender {
    if (self.addressBook.selectedPhoneNumbers.count == 0) {
        [self.navigationController popViewControllerAnimated:NO];
        return;
    }
    sender.loading = YES;
    self.view.userInteractionEnabled = NO;
    __weak typeof(self)weakSelf = self;
    [[WLAPIRequest addContributors:self.addressBook.selectedPhoneNumbers wrap:self.wrap] send:^(id object) {
        [weakSelf.navigationController popViewControllerAnimated:NO];
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
    WLAddressBookRecordCell* cell = [WLAddressBookRecordCell cellWithContact:contact inTableView:tableView indexPath:indexPath];
	cell.opened = ([contact.phoneNumbers count] > 1 && [self openedIndexPath:indexPath] != nil);
    
    if ([tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        cell.preservesSuperviewLayoutMargins = NO;
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    WLArrangedAddressBookGroup *group = self.filteredAddressBook.groups[indexPath.section];
	WLAddressBookRecord* contact = group.records[indexPath.row];
    return [self heightForRowWithContact:contact indexPath:indexPath];
}

const static CGFloat WLDefaultHeight = 72.0f;

- (CGFloat)heightForRowWithContact:(WLAddressBookRecord *)contact indexPath:(NSIndexPath*)indexPath {
    if ([contact.phoneNumbers count] > 1) {
        if ([self openedIndexPath:indexPath] != nil) {
            return WLDefaultHeight + [contact.phoneNumbers count] * 50.0f;
        } else {
            return WLDefaultHeight;
        }
    } else {
        NSString *phoneString = [WLAddressBookRecordCell collectionPersonsStringFromContact:contact];
        CGFloat height = [phoneString heightWithFont:[UIFont preferredDefaultFontWithPreset:WLFontPresetSmall]
                                       width:self.tableView.width - 142.0f];
        return height + 54.0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    WLArrangedAddressBookGroup *group = self.filteredAddressBook.groups[section];
    return group.title.nonempty && group.records.nonempty ? 32.0 : 0;
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

- (WLContactCellState)contactCell:(WLAddressBookRecordCell *)cell phoneNumberState:(WLAddressBookPhoneNumber *)phoneNumber {
    if ([self.wrap.contributors containsObject:phoneNumber.user]) {
        return WLContactCellStateAdded;
    }
    return [self.addressBook selectedPhoneNumber:phoneNumber] != nil ? WLContactCellStateSelected : WLContactCellStateDefault;
}

- (void)contactCell:(WLAddressBookRecordCell *)cell didSelectPerson:(WLAddressBookPhoneNumber *)person {
    
    [self.addressBook selectPhoneNumber:person];
	
	NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
	if (indexPath) {
		[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
	}
}

- (NSIndexPath*)openedIndexPath:(NSIndexPath*)indexPath {
    for (NSIndexPath* _indexPath in self.openedRows) {
        if ([_indexPath compare:indexPath] == NSOrderedSame) {
            return _indexPath;
        }
    }
    return nil;
}

- (void)contactCellDidToggle:(WLAddressBookRecordCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (indexPath) {
        NSIndexPath *existingIndexPath = [self openedIndexPath:indexPath];
        if (existingIndexPath) {
            [self.openedRows removeObject:existingIndexPath];
        } else {
            [self.openedRows addObject:indexPath];
        }
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
    }
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

- (void)inviteViewController:(WLInviteViewController *)controller didInviteContact:(WLAddressBookRecord *)contact {
    if (!self.addressBook) {
        self.addressBook = [[WLArrangedAddressBook alloc] initWithWrap:self.wrap];
        [self.addressBook addRecord:contact];
        [self filterContacts];
        [self.navigationController popToViewController:self animated:NO];
        return;
    }
    __weak typeof(self)weakSelf = self;
    [self.addressBook addUniqueRecord:contact success:^(BOOL exists, NSArray *records, NSArray *groups) {
        WLAddressBookRecord *record = [records lastObject];
        WLArrangedAddressBookGroup *group = [groups lastObject];
        if (!exists) {
            [weakSelf.invitedRecords addObject:record];
        }
        [weakSelf.addressBook selectPhoneNumber:[record.phoneNumbers firstObject]];
        [weakSelf filterContacts];
        NSUInteger section = [weakSelf.addressBook.groups indexOfObject:group];
        NSUInteger row = [group.records indexOfObject:record];
        if (row != NSNotFound && section != NSNotFound) {
            [weakSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]
                                      atScrollPosition:UITableViewScrollPositionMiddle
                                              animated:NO];
        }
        [weakSelf.navigationController popToViewController:weakSelf animated:NO];
    } failure:^(NSError *error) {
        [error show];
    }];
}

#pragma mark - WLFontPresetterReceiver

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter *)presetter {
    [self.tableView reloadData];
}

@end
