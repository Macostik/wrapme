//
//  WLContributorsViewController.m
//  meWrap
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

@interface WLAddContributorsViewController () <StreamViewDelegate, WLAddressBookRecordCellDelegate, UITextFieldDelegate, WLInviteViewControllerDelegate, WLFontPresetterReceiver, WLAddressBookReceiver>

@property (weak, nonatomic) IBOutlet StreamView *streamView;
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
    [self.streamView reload];
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

#pragma mark - StreamViewDelegate

- (NSInteger)streamViewNumberOfSections:(StreamView * __nonnull)streamView {
	return [self.filteredAddressBook.groups count];
}

- (NSInteger)streamView:(StreamView * __nonnull)streamView numberOfItemsInSection:(NSInteger)section {
    WLArrangedAddressBookGroup *group = self.filteredAddressBook.groups[section];
	return [group.records count];
}

- (NSArray *)streamView:(StreamView * __nonnull)streamView sectionHeaderMetricsInSection:(NSInteger)section {
    return @[[[StreamMetrics alloc] initWithIdentifier:@"WLAddressBookGroupView" initializer:^(StreamMetrics *metrics) {
        
    }]];
}

- (id)streamView:(StreamView * __nonnull)streamView entryAt:(StreamIndex * __nonnull)index {
    WLArrangedAddressBookGroup *group = [self.filteredAddressBook.groups tryAt:index.section];
    return [group.records tryAt:index.item];
}

- (NSArray * __nonnull)streamView:(StreamView * __nonnull)streamView metricsAt:(StreamIndex * __nonnull)index {
    WLArrangedAddressBookGroup *group = [self.filteredAddressBook.groups tryAt:index.section];
    WLAddressBookRecord* record = [group.records tryAt:index.item];
    __weak typeof(self)weakSelf = self;
    if ([record.phoneNumbers count] > 1) {
        return @[[[StreamMetrics alloc] initWithIdentifier:@"WLMultipleAddressBookRecordCell" initializer:^(StreamMetrics *metrics) {
            metrics.nibOwner = weakSelf;
            [metrics setSizeAt:^CGFloat(StreamIndex *index, StreamMetrics *metrics) {
                return [weakSelf openedIndex:index] ? (72.0f + [record.phoneNumbers count] * 50.0f) : 72.0f;
            }];
            [metrics setFinalizeAppearing:^(StreamItem *item, WLAddressBookRecord *record) {
                WLAddressBookRecordCell *cell = (id)item.view;
                cell.opened = ([record.phoneNumbers count] > 1 && [weakSelf openedIndex:item.index] != nil);
            }];
        }]];
    } else {
        return @[[[StreamMetrics alloc] initWithIdentifier:@"WLAddressBookRecordCell" initializer:^(StreamMetrics *metrics) {
            metrics.nibOwner = weakSelf;
            [metrics setSizeAt:^CGFloat(StreamIndex *index, StreamMetrics *metrics) {
                return [record.phoneStrings heightWithFont:[UIFont preferredDefaultFontWithPreset:WLFontPresetSmall] width:weakSelf.streamView.width - 142.0f] + 54;
            }];
        }]];
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

#pragma mark - WLAddressBookRecordCellDelegate

- (WLAddressBookPhoneNumberState)recordCell:(WLAddressBookRecordCell *)cell phoneNumberState:(WLAddressBookPhoneNumber *)phoneNumber {
    if ([self.wrap.contributors containsObject:phoneNumber.user]) {
        return WLAddressBookPhoneNumberStateAdded;
    }
    return [self.addressBook selectedPhoneNumber:phoneNumber] != nil ? WLAddressBookPhoneNumberStateSelected : WLAddressBookPhoneNumberStateDefault;
}

- (void)recordCell:(WLAddressBookRecordCell *)cell didSelectPhoneNumber:(WLAddressBookPhoneNumber *)person {
    [self.addressBook selectPhoneNumber:person];
    [cell resetup];
}

- (StreamIndex*)openedIndex:(StreamIndex*)index {
    return [self.openedRows select:^BOOL(StreamIndex* _index) {
        return [_index isEqualToIndex:index];
    }];
}

- (void)recordCellDidToggle:(WLAddressBookRecordCell *)cell {
    StreamIndex *index = [self.streamView itemPassingTest:^BOOL(StreamItem *item) {
        return item.view == cell;
    }].index;
    if (index) {
        StreamIndex *existingIndex = [self openedIndex:index];
        if (existingIndex) {
            [self.openedRows removeObject:existingIndex];
        } else {
            [self.openedRows addObject:index];
        }
#warning  implement animated layout uopdate
        [self.streamView reload];
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
        [weakSelf.streamView scrollToItem:[weakSelf.streamView itemPassingTest:^BOOL(StreamItem *item) {
            return item.index.section == section && item.index.item == row;
        }] animated:NO];
        [weakSelf.navigationController popToViewController:weakSelf animated:NO];
    } failure:^(NSError *error) {
        [error show];
    }];
}

#pragma mark - WLFontPresetterReceiver

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter *)presetter {
    [self.streamView reload];
}

@end
