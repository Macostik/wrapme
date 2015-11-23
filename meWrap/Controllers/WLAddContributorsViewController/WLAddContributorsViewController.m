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
#import "WLAddressBookPhoneNumber.h"
#import "WLButton.h"
#import "WLArrangedAddressBook.h"
#import "WLAddressBookGroupView.h"

@interface WLAddContributorsViewController () <StreamViewDelegate, WLAddressBookRecordCellDelegate, UITextFieldDelegate, FontPresetting, WLAddressBookReceiver>

@property (weak, nonatomic) IBOutlet StreamView *streamView;
@property (weak, nonatomic) IBOutlet UITextField *searchField;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, strong) NSMutableArray* openedRows;

@property (strong, nonatomic) WLArrangedAddressBook* addressBook;

@property (strong, nonatomic) WLArrangedAddressBook* filteredAddressBook;

@property (strong, nonatomic) StreamMetrics *singleMetrics;

@property (strong, nonatomic) StreamMetrics *multipleMetrics;

@property (strong, nonatomic) StreamMetrics *sectionHeaderMetrics;

@end

@implementation WLAddContributorsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.openedRows = [NSMutableArray array];
    [self.spinner startAnimating];
    
    __weak typeof(self)weakSelf = self;
    
    self.singleMetrics = [[StreamMetrics alloc] initWithIdentifier:@"WLAddressBookRecordCell" initializer:^(StreamMetrics *metrics) {
        [metrics setSizeAt:^CGFloat(StreamPosition *position, StreamMetrics *metrics) {
            WLArrangedAddressBookGroup *group = [weakSelf.filteredAddressBook.groups tryAt:position.section];
            WLAddressBookRecord* record = [group.records tryAt:position.index];
            return [record.phoneStrings heightWithFont:[UIFont fontSmall] width:weakSelf.streamView.width - 142.0f] + 54;
        }];
    }];
    
    self.multipleMetrics = [[StreamMetrics alloc] initWithIdentifier:@"WLMultipleAddressBookRecordCell" initializer:^(StreamMetrics *metrics) {
        metrics.selectable = NO;
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
    
	
    BOOL cached = [[WLAddressBook addressBook] cachedRecords:^(NSSet *array) {
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
    [[FontPresetter defaultPresetter] addReceiver:self];
}

- (void)filterContacts {
    self.filteredAddressBook  = [self.addressBook filteredAddressBookWithText:self.searchField.text];
    [self.streamView reload];
}

// MARK: - WLAddressBookReceiver

- (void)addressBook:(WLAddressBook *)addressBook didUpdateCachedRecords:(NSSet *)cachedRecords {
    [self.spinner stopAnimating];
    WLArrangedAddressBook *oldAddressBook = self.addressBook;
    self.addressBook = [[WLArrangedAddressBook alloc] initWithWrap:self.wrap];
    [self.addressBook addRecords:cachedRecords];
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

- (id  _Nullable (^)(StreamItem * _Nonnull))streamView:(StreamView *)streamView entryBlockForItem:(StreamItem *)item {
    __weak typeof(self)weakSelf = self;
    return ^id (StreamItem *item) {
        WLArrangedAddressBookGroup *group = [weakSelf.filteredAddressBook.groups tryAt:item.position.section];
        return [group.records tryAt:item.position.index];
    };
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
    StreamPosition *position = cell.item.position;
    if (position) {
        StreamPosition *_position = [self openedPosition:position];
        if (_position) {
            [self.openedRows removeObject:_position];
        } else {
            [self.openedRows addObject:position];
        }
#warning implement animated layout update
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

- (void)presetterDidChangeContentSizeCategory:(FontPresetter *)presetter {
    [self.streamView reload];
}

@end
