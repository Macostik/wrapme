//
//  WLContributorsViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 25.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#define registeredContacts   contacts[0]
#define unregisteredContacts contacts[1]
#define filteredRegisteredContacts filteredContacts[0]
#define filteredUnregisteredContacts filteredContacts[1]

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
#import "WLPerson.h"
#import "WLContributorsRequest.h"
#import "WLButton.h"
#import "WLEntryNotifier.h"
#import "WLUpdateContributorsRequest.h"
#import "WLFontPresetter.h"

@interface WLAddContributorsViewController () <UITableViewDataSource, UITableViewDelegate, WLContactCellDelegate, UITextFieldDelegate, WLInviteViewControllerDelegate, WLFontPresetterReceiver>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *searchField;

@property (strong, nonatomic) NSMutableArray* contacts;
@property (strong, nonatomic) NSMutableArray* filteredContacts;

@property (strong, nonatomic) NSMutableSet* selectedPhones;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, strong) NSMutableSet* openedRows;

@end

@implementation WLAddContributorsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.contacts = [NSMutableArray array];
    self.registeredContacts = [NSMutableArray array];
    self.unregisteredContacts = [NSMutableArray array];
    self.filteredContacts = [NSMutableArray array];
    [self.spinner startAnimating];
	__weak typeof(self)weakSelf = self;
    [[WLContributorsRequest request] send:^(id object) {
        [weakSelf processContacts:object];
		[weakSelf.spinner stopAnimating];
    } failure:^(NSError *error) {
        [weakSelf.spinner stopAnimating];
		[error show];
    }];
    [[WLFontPresetter presetter] addReceiver:self];
}

- (NSError*)addContact:(WLContact*)contact {
    NSMutableArray *registered = self.registeredContacts;
    NSMutableArray *unregistered = self.unregisteredContacts;
    NSMutableArray *persons = [contact.persons mutableCopy];
    
    if (!persons.nonempty) {
        return [NSError errorWithDescription:@"No contact data."];
    }
    
    BOOL currentUserRemoved = NO;
    [self willRemoveDoublePersons:persons currentUserRemoved:&currentUserRemoved];
    
    if (!persons.nonempty) {
        return [NSError errorWithDescription:currentUserRemoved ? @"You cannot add yourself." : @"This contact is already added."];
    } else if ([persons count] == 1) {
        WLPerson* person = [persons lastObject];
        contact.persons = [persons copy];
        if (person.user) {
            [registered addObject:contact];
        } else {
            [unregistered addObject:contact];
        }
    } else {
        [persons removeObjectsWhileEnumerating:^BOOL(WLPerson *person) {
            if (person.user) {
                WLContact* _contact = [[WLContact alloc] init];
                _contact.persons = @[person];
                [registered addObject:_contact];
                return YES;
            }
            return NO;
        }];
        if (persons.nonempty) {
            contact.persons = [persons copy];
            [unregistered addObject:contact];
        }
    }
    return nil;
}

- (void)willRemoveDoublePersons:(NSMutableArray *)persons currentUserRemoved:(BOOL *)currentUserRemoved {
    [persons removeObjectsWhileEnumerating:^BOOL(WLPerson *person) {
        if (person.user) {
            if ([self.wrap.contributors containsObject:person.user]) {
                if (currentUserRemoved != NULL && [person.user isCurrentUser]) {
                    *currentUserRemoved = YES;
                }
                return YES;
            }
        }
        return NO;
    }];
}

- (void)processContacts:(NSArray*)contacts {
    for (WLContact* contact in contacts) {
        [self addContact:contact];
    }
    [self sortContacts];
    [self filterContacts];
}

- (void)sortContacts {
    NSComparator comparator = ^NSComparisonResult(WLContact* contact1, WLContact* contact2) {
        return [[contact1 name] compare:[contact2 name]];
    };
    [self.registeredContacts sortUsingComparator:comparator];
    [self.unregisteredContacts sortUsingComparator:comparator];
}

- (void)filterContacts {
    if ([self.searchField.text nonempty]) {
        self.filteredContacts  = [self filteredContactsByString:self.searchField.text];
    } else {
        self.filteredContacts = self.contacts;
    }
    [self.tableView reloadData];
}

- (NSMutableSet *)openedRows {
	if (!_openedRows) {
		_openedRows = [NSMutableSet set];
	}
	return _openedRows;
}

- (NSMutableSet *)selectedPhones {
	if (!_selectedPhones) {
		_selectedPhones = [NSMutableSet set];
	}
	return _selectedPhones;
}

-(void)setContacts:(NSMutableArray *)contacts {
    _contacts = contacts;
    [self.tableView reloadData];
}

-(void)setFilteredContacts:(NSMutableArray *)filteredContacts {
    _filteredContacts = filteredContacts;
    [self.tableView reloadData];
}

- (WLPerson*)selectedPerson:(WLPerson*)person {
    for (WLPerson* _person in self.selectedPhones) {
        if ([_person isEqualToPerson:person]) {
            return _person;
        }
	}
	return nil;
}

#pragma mark - Actions

- (IBAction)done:(WLButton*)sender {
    if (self.selectedPhones.count == 0) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    WLUpdateContributorsRequest *updateConributors = [WLUpdateContributorsRequest request:self.wrap];
    updateConributors.contributors = [self.selectedPhones allObjects];
    updateConributors.isAddContirbutor = [self.selectedPhones allObjects].nonempty;
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
	return [self.filteredContacts count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.filteredContacts[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLContact* contact = self.filteredContacts[indexPath.section][indexPath.row];
    WLContactCell* cell = [WLContactCell cellWithContact:contact inTableView:tableView indexPath:indexPath];
	cell.opened = ([contact.persons count] > 1 && [self.openedRows containsObject:contact]);
    
    if ([tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        cell.preservesSuperviewLayoutMargins = NO;
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLContact* contact = self.filteredContacts[indexPath.section][indexPath.row];
    return [self heightForRowWithContact:contact];
}

const static CGFloat WLIndent = 31.0f;
const static CGFloat WLDefaultHeight = 50.0f;

- (CGFloat)heightForRowWithContact:(WLContact *)contact {
    if ([contact.persons count] > 1) {
        if ([self.openedRows containsObject:contact]) {
            return WLDefaultHeight + [contact.persons count] * WLDefaultHeight;
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
	return section ? 0.5f : 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	if (section) {
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor WL_orangeColor];
        return view;
    }
    return nil;
}

#pragma mark - WLContactCellDelegate

- (BOOL)contactCell:(WLContactCell *)cell personSelected:(WLPerson *)person {
	return [self selectedPerson:person] != nil;
}

- (void)contactCell:(WLContactCell *)cell didSelectPerson:(WLPerson *)person {
    
    WLPerson* _person = [self selectedPerson:person];
	if (_person) {
		[self.selectedPhones removeObject:_person];
	} else {
		[self.selectedPhones addObject:person];
	}
	
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
    if ([sender.text nonempty]) {
        self.filteredContacts = [self filteredContactsByString:sender.text];
    } else {
        self.filteredContacts = self.contacts.mutableCopy;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self filterContacts];
	[textField resignFirstResponder];
	return YES;
}

- (NSMutableArray *)filteredContactsByString:(NSString *)searchString {
    return [NSMutableArray arrayWithObjects:[self.registeredContacts filteredArrayUsingPredicate:[self searchText:searchString]],
                                            [self.unregisteredContacts filteredArrayUsingPredicate:[self searchText:searchString]], nil];
}

- (NSPredicate *)searchText:(NSString *)searchText{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name contains[c] %@", searchText];
	return predicate;
}

#pragma mark - WLInviteViewControllerDelegate

- (NSError *)inviteViewController:(WLInviteViewController *)controller didInviteContact:(WLContact *)contact {
    WLPerson *person = [contact.persons lastObject];
    
    SelectBlock selectBlock = ^BOOL(WLContact* item) {
        for (WLPerson* _person in item.persons) {
            if ([_person isEqualToPerson:person]) {
                person.name = item.name;
                return YES;
            }
        }
        return NO;
    };
    
    WLContact* existingContact = [self.registeredContacts selectObject:selectBlock] ? :
    [self.unregisteredContacts selectObject:selectBlock];
    
    if (!existingContact) {
        NSError* error = [self addContact:contact];
        if (error == nil) {
            existingContact = contact;
            [self.selectedPhones addObject:person];
        } else {
            return error;
        }
    } else if ([self selectedPerson:person] == nil) {
        [self.selectedPhones addObject:person];
    }
    
    [self sortContacts];
    [self filterContacts];
    
    NSUInteger index = NSNotFound;
    NSUInteger section = 0;
    if ([self.filteredRegisteredContacts containsObject:existingContact]) {
        index = [self.filteredRegisteredContacts indexOfObject:existingContact];
    } else {
        index = [self.filteredUnregisteredContacts indexOfObject:existingContact];
        section = 1;
    }
    
    if (index != NSNotFound) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:section]
                              atScrollPosition:UITableViewScrollPositionMiddle
                                      animated:YES];
    }
    return nil;
}

#pragma mark - WLFontPresetterReceiver

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter *)presetter {
    [self.tableView reloadData];
}

@end
