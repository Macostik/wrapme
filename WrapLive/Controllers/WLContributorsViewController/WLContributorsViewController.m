//
//  WLContributorsViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 25.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLContributorsViewController.h"
#import "WLAPIManager.h"
#import "WLAddressBook.h"
#import "NSArray+Additions.h"
#import "NSString+Additions.h"
#import "WLContactCell.h"
#import "UIColor+CustomColors.h"
#import "WLInviteViewController.h"
#import "WLEntryManager.h"

@interface WLContributorsViewController () <UITableViewDataSource, UITableViewDelegate, WLContactCellDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *searchField;
@property (strong, nonatomic) NSArray* contacts;
@property (strong, nonatomic) NSMutableSet* selectedPhones;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, strong) NSMutableSet* openedRows;
@property (nonatomic) NSInteger separatorSection;

@end

@implementation WLContributorsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	[self.spinner startAnimating];
	__weak typeof(self)weakSelf = self;
	[[WLAPIManager instance] contributors:^(NSArray* contacts) {
		weakSelf.contacts = [weakSelf processContacts:contacts];
		[weakSelf.spinner stopAnimating];
	} failure:^(NSError *error) {
		[weakSelf.spinner stopAnimating];
		[error show];
	}];
}

- (NSArray*)processContacts:(NSArray*)contacts {
	NSMutableArray* signedUp = [NSMutableArray array];
	NSMutableArray* notSignedUp = [NSMutableArray array];
	for (WLContact* contact in contacts) {
		
		NSMutableArray *phones = [contact.phones mutableCopy];
        [phones removeObjectsWhileEnumerating:^BOOL(WLPhone *phone) {
            return ([phone.user isEqualToEntry:[WLUser currentUser]] || (self.wrap.contributor && [phone.user isEqualToEntry:self.wrap.contributor]));
        }];
        
        if (!phones.nonempty) {
            continue;
        } else if ([phones count] == 1) {
			WLPhone* phone = [phones lastObject];
            contact.phones = [phones copy];
			if (phone.user) {
				[signedUp addObject:contact];
			} else {
				[notSignedUp addObject:contact];
			}
		} else {
			[phones removeObjectsWhileEnumerating:^BOOL(WLPhone *phone) {
				if (phone.user) {
					WLContact* _contact = [[WLContact alloc] init];
					_contact.phones = @[phone];
					[signedUp addObject:_contact];
					return YES;
				}
				return NO;
			}];
			if (phones.nonempty) {
				contact.phones = [phones copy];
				[notSignedUp addObject:contact];
			}
		}
	}
	NSComparator comparator = ^NSComparisonResult(WLContact* contact1, WLContact* contact2) {
		return [[contact1 name] compare:[contact2 name]];
	};
	
	[signedUp sortUsingComparator:comparator];
	[notSignedUp sortUsingComparator:comparator];
	self.separatorSection = [signedUp count];
	return [signedUp arrayByAddingObjectsFromArray:notSignedUp];
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

- (void)setWrap:(WLWrap *)wrap {
	_wrap = wrap;
    NSOrderedSet* phones = [wrap.contributors map:^id(WLUser* contributor) {
        WLPhone* phone = [[WLPhone alloc] init];
        phone.number = contributor.phone;
        phone.name = contributor.name;
        phone.user = contributor;
        return phone;
    }];
	[self.selectedPhones setSet:[phones set]];
}

-(void)setContacts:(NSArray *)contacts {
    _contacts = contacts;
    [self.tableView reloadData];
}

- (WLPhone*)selectedPhone:(WLPhone*)phone {
    for (WLPhone* _phone in self.selectedPhones) {
        if ([_phone isEqualToPhone:phone]) {
            return _phone;
        }
	}
	return nil;
}

#pragma mark - Actions

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	WLInviteViewController *controller = segue.destinationViewController;
	__weak typeof(self)weakSelf = self;
	[controller setPhoneNumberBlock:^(NSArray *contacts) {
        WLContact* contact = [contacts lastObject];

        [self.selectedPhones addObjectsFromArray:contact.phones];
        
        WLContact* existingContact = [weakSelf.contacts selectObject:^BOOL(WLContact* item) {
            for (WLPhone* phone in item.phones) {
                for (WLPhone* _phone in contact.phones) {
                    if ([_phone isEqualToPhone:phone]) {
                        return YES;
                    }
                }
            }
            return NO;
        }];
        
        NSMutableArray* aContacts = [NSMutableArray arrayWithArray:weakSelf.contacts];
        
        if (!existingContact) {
            [aContacts addObject:contact];
            existingContact = contact;
        }
        
		weakSelf.contacts = [weakSelf processContacts:[aContacts copy]];
		
        NSUInteger index = [weakSelf.contacts indexOfObject:existingContact];
        if (index != NSNotFound) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:index]
                                  atScrollPosition:UITableViewScrollPositionMiddle
                                          animated:YES];
        }
		
	}];
}

- (IBAction)back:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)done:(id)sender {
    NSMutableOrderedSet* contributors = [NSMutableOrderedSet orderedSetWithOrderedSet:self.wrap.contributors];
    
    NSMutableArray* invitees = [NSMutableArray array];
    
    for (WLPhone* phone in self.selectedPhones) {
        if (phone.user) {
            [contributors addObject:phone.user];
        } else {
            [invitees addObject:phone];
        }
    }
	self.wrap.contributors = [contributors copy];
    self.wrap.invitees = [invitees copy];
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)searchTextChanged:(UITextField *)sender {
	[self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [self.contacts count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSString* searchText = self.searchField.text;
	if (searchText.nonempty) {
		WLContact* contact = self.contacts[section];
		if ([contact.name rangeOfString:searchText options:NSCaseInsensitiveSearch].location == NSNotFound) {
			return 0;
		}
	}
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLContact* contact = self.contacts[indexPath.section];
    WLContactCell* cell = [WLContactCell cellWithContact:contact inTableView:tableView indexPath:indexPath];
	cell.opened = ([contact.phones count] > 1 && [self.openedRows containsObject:contact]);
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLContact* contact = self.contacts[indexPath.section];
	if ([contact.phones count] > 1 && [self.openedRows containsObject:contact]) {
		return 50 + [contact.phones count]*50;
	}
	return 50;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return self.separatorSection == section ? 0.5f : 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	if (self.separatorSection == section) {
		UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 0.5f)];
		view.backgroundColor = [UIColor WL_orangeColor];
		return view;
	}
	return nil;
}

#pragma mark - WLContactCellDelegate

- (BOOL)contactCell:(WLContactCell *)cell phoneSelected:(WLPhone *)phone {
	return [self selectedPhone:phone] != nil;
}

- (void)contactCell:(WLContactCell *)cell didSelectPhone:(WLPhone *)phone {
    
    WLPhone* _phone = [self selectedPhone:phone];
	if (_phone) {
		[self.selectedPhones removeObject:_phone];
	} else {
		[self.selectedPhones addObject:phone];
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	[self.tableView reloadData];
	return YES;
}

@end
