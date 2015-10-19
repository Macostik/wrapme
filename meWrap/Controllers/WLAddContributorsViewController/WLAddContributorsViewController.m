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
#import "WLAddressBookPhoneNumber.h"
#import "WLButton.h"
#import "WLFontPresetter.h"
#import "WLArrangedAddressBook.h"
#import "WLAddressBookGroupView.h"
#import "NSObject+NibAdditions.h"

@interface WLAddContributorsViewController () <StreamViewDelegate, WLAddressBookRecordCellDelegate, UITextFieldDelegate, WLFontPresetterReceiver, WLAddressBookReceiver>

@property (weak, nonatomic) IBOutlet StreamView *streamView;
@property (weak, nonatomic) IBOutlet UITextField *searchField;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, strong) NSMutableArray* openedRows;

@property (strong, nonatomic) WLArrangedAddressBook* addressBook;

@property (strong, nonatomic) WLArrangedAddressBook* filteredAddressBook;

@property (strong, nonatomic) NSMutableSet* invitedRecords;

@property (strong, nonatomic) StreamMetrics *singleMetrics;

@property (strong, nonatomic) StreamMetrics *multipleMetrics;

@property (strong, nonatomic) StreamMetrics *sectionHeaderMetrics;

@end

@implementation WLAddContributorsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.invitedRecords = [NSMutableSet set];
    self.openedRows = [NSMutableArray array];
    [self.spinner startAnimating];
    
    __weak typeof(self)weakSelf = self;
    
    self.singleMetrics = [[StreamMetrics alloc] initWithIdentifier:@"WLAddressBookRecordCell" initializer:^(StreamMetrics *metrics) {
        [metrics setSizeAt:^CGFloat(StreamPosition *position, StreamMetrics *metrics) {
            WLArrangedAddressBookGroup *group = [weakSelf.filteredAddressBook.groups tryAt:position.section];
            WLAddressBookRecord* record = [group.records tryAt:position.index];
            return [record.phoneStrings heightWithFont:[UIFont preferredDefaultFontWithPreset:WLFontPresetSmall] width:weakSelf.streamView.width - 142.0f] + 54;
        }];
    }];
    
    self.multipleMetrics = [[StreamMetrics alloc] initWithIdentifier:@"WLMultipleAddressBookRecordCell" initializer:^(StreamMetrics *metrics) {
        [metrics setSizeAt:^CGFloat(StreamPosition *position, StreamMetrics *metrics) {
            WLArrangedAddressBookGroup *group = [weakSelf.filteredAddressBook.groups tryAt:position.section];
            WLAddressBookRecord* record = [group.records tryAt:position.index];
            return [weakSelf openedPosition:position] ? (72.0f + [record.phoneNumbers count] * 50.0f) : 72.0f;
        }];
        [metrics setFinalizeAppearing:^(StreamItem *item, WLAddressBookRecord *record) {
            WLAddressBookRecordCell *cell = (id)item.view;
            cell.opened = ([record.phoneNumbers count] > 1 && [weakSelf openedPosition:item.position] != nil);
        }];
    }];
    
    self.sectionHeaderMetrics = [[StreamMetrics alloc] initWithInitializer:^(StreamMetrics *metrics) {
        metrics.identifier = @"WLAddressBookGroupView";
        metrics.size = 32;
        [metrics setHiddenAt:^BOOL(StreamPosition *position, StreamMetrics *metrics) {
            WLArrangedAddressBookGroup *group = [weakSelf.filteredAddressBook.groups tryAt:position.section];
            return !(group.title.nonempty && group.records.nonempty);
        }];
        [metrics setFinalizeAppearing:^(StreamItem *item, id entry) {
            WLAddressBookGroupView *view = (id)item.view;
            view.group = [weakSelf.filteredAddressBook.groups tryAt:item.position.section];
        }];
    }];
    
	
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

- (NSArray *)streamView:(StreamView * __nonnull)streamView headerMetricsInSection:(NSInteger)section {
    return @[self.sectionHeaderMetrics];
}

- (void)streamView:(StreamView * __nonnull)streamView didLayoutItem:(StreamItem * __nonnull)item {
    WLArrangedAddressBookGroup *group = [self.filteredAddressBook.groups tryAt:item.position.section];
    item.entry = [group.records tryAt:item.position.index];
}

- (NSArray * __nonnull)streamView:(StreamView * __nonnull)streamView metricsAt:(StreamPosition * __nonnull)position {
    WLArrangedAddressBookGroup *group = [self.filteredAddressBook.groups tryAt:position.section];
    WLAddressBookRecord* record = [group.records tryAt:position.index];
    StreamMetrics *metrics = nil;
    __weak typeof(self)weakSelf = self;
    if ([record.phoneNumbers count] > 1) {
        metrics = self.multipleMetrics;
    } else {
        metrics = self.singleMetrics;
    }
    metrics.nibOwner = weakSelf;
    return @[metrics];
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

- (StreamPosition*)openedPosition:(StreamPosition*)position {
    return [self.openedRows select:^BOOL(StreamPosition* _position) {
        return [_position isEqualToPosition:position];
    }];
}

- (void)recordCellDidToggle:(WLAddressBookRecordCell *)cell {
    StreamPosition *position = [self.streamView itemPassingTest:^BOOL(StreamItem *item) {
        return item.view == cell;
    }].position;
    if (position) {
        StreamPosition *_position = [self openedPosition:position];
        if (_position) {
            [self.openedRows removeObject:_position];
        } else {
            [self.openedRows addObject:position];
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

#pragma mark - WLFontPresetterReceiver

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter *)presetter {
    [self.streamView reload];
}

@end
