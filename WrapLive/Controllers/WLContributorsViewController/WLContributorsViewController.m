//
//  WLContributorsViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 25.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#define kRegisterContacts   self.contacts[0]
#define kUnregisterContacts self.contacts[1]
#define kWeakRegisterContacts   weakSelf.contacts[0]
#define kWeakUnregisterContacts weakSelf.contacts[1]
#define kWeakFilteredContactsFirstSection weakSelf.filteredContacts[0]
#define kWeakFilteredContactsSecondSection weakSelf.filteredContacts[1]

#import "WLContributorsViewController.h"
#import "WLAPIManager.h"
#import "WLAddressBook.h"
#import "NSArray+Additions.h"
#import "NSString+Additions.h"
#import "WLContactCell.h"
#import "UIColor+CustomColors.h"
#import "WLInviteViewController.h"
#import "WLEntryManager.h"
#import "WLPerson.h"
#import "WLContributorsRequest.h"

@interface WLContributorsViewController () <UITableViewDataSource, UITableViewDelegate, WLContactCellDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *searchField;
@property (strong, nonatomic) NSMutableArray* contacts;
@property (strong, nonatomic) NSMutableArray* filteredContacts;
@property (strong, nonatomic) NSMutableSet* selectedPhones;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, strong) NSMutableSet* openedRows;

@end

@implementation WLContributorsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.contacts = [NSMutableArray array];
    kRegisterContacts = [NSMutableArray array];
    kUnregisterContacts = [NSMutableArray array];
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
}

- (void)addContact:(WLContact*)contact {
    NSMutableArray *registerContactsArray = kRegisterContacts;
    NSMutableArray *unregisterContactsArray = kUnregisterContacts;
    NSMutableArray *persons = [contact.persons mutableCopy];
    
    [self willRemoveDoublePersons:persons];
    
    if (!persons.nonempty) {
        return;
    } else if ([persons count] == 1) {
        WLPerson* person = [persons lastObject];
        contact.persons = [persons copy];
        if (person.user) {
            [registerContactsArray addObject:contact];
        } else {
            [unregisterContactsArray addObject:contact];
        }
    } else {
        [persons removeObjectsWhileEnumerating:^BOOL(WLPerson *person) {
            if (person.user) {
                WLContact* _contact = [[WLContact alloc] init];
                _contact.persons = @[person];
                [registerContactsArray addObject:_contact];
                return YES;
            }
            return NO;
        }];
        if (persons.nonempty) {
            contact.persons = [persons copy];
            [unregisterContactsArray addObject:contact];
        }
    }
}

- (void)willRemoveDoublePersons:(NSMutableArray *)persons {
    [persons removeObjectsWhileEnumerating:^BOOL(WLPerson *person) {
        if (person.user) {
            if ([self.contributors containsObject:person.user]) {
                return YES;
            }
        }
        return [self.invitees containsObject:person byBlock:^BOOL(WLPerson* first, WLPerson* second) {
            return [first isEqualToPerson:second];
        }];
    }];
}

- (void)checkFewPhonesPersons:(NSMutableArray *)persons {
    
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
    [kRegisterContacts sortUsingComparator:comparator];
    [kUnregisterContacts sortUsingComparator:comparator];
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	WLInviteViewController *controller = segue.destinationViewController;
	__weak typeof(self)weakSelf = self;
	controller.contactBlock = ^(WLContact *contacts) {
        WLPerson *person = [contacts.persons lastObject];
        [self.selectedPhones addObjectsFromArray:contacts.persons];
        
        SelectBlock selectBlock = ^BOOL(WLContact* item) {
            for (WLPerson* _person in item.persons) {
                if ([_person isEqualToPerson:person]) {
                    person.name = item.name;
                    return YES;
                }
            }
             return NO;
        };
        
        WLContact* existingContact = [kWeakRegisterContacts selectObject:selectBlock] ? :
                                     [kWeakUnregisterContacts selectObject:selectBlock];
        
        if (!existingContact) {
            existingContact = contacts;
            [weakSelf addContact:contacts];
        }
       
        [weakSelf sortContacts];
        [weakSelf filterContacts];
        
        NSUInteger index = NSNotFound;
        NSUInteger section = 0;
		if ([kWeakFilteredContactsFirstSection containsObject:existingContact]) {
            index = [kWeakFilteredContactsFirstSection indexOfObject:existingContact];
        } else {
            index = [kWeakFilteredContactsSecondSection indexOfObject:existingContact];
            section = 1;
        }
       
        if (index != NSNotFound) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:section]
                                  atScrollPosition:UITableViewScrollPositionMiddle
                                          animated:YES];
        }
	};
}

- (IBAction)done:(id)sender {
    self.contactsBlock([self.selectedPhones allObjects]);
	[self.navigationController popViewControllerAnimated:YES];
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
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLContact* contact = self.filteredContacts[indexPath.section][indexPath.row];
	if ([contact.persons count] > 1 && [self.openedRows containsObject:contact]) {
		return 50 + [contact.persons count]*50;
	}
	return 50;
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
    return [NSMutableArray arrayWithObjects:[kRegisterContacts filteredArrayUsingPredicate:[self searchText:searchString]],
                                            [kUnregisterContacts filteredArrayUsingPredicate:[self searchText:searchString]], nil];
}

- (NSPredicate *)searchText:(NSString *)searchText{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name contains[c] %@", searchText];
	return predicate;
}

@end
