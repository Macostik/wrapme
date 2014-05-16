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
#import "WLWrap.h"
#import "NSArray+Additions.h"
#import "WLUser.h"
#import "NSString+Additions.h"
#import "WLContactCell.h"
#import "UIColor+CustomColors.h"

@interface WLContributorsViewController () <UITableViewDataSource, UITableViewDelegate, WLContactCellDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *searchField;
@property (strong, nonatomic) NSArray* contributors;
@property (strong, nonatomic) NSMutableArray* selectedContributors;
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
	[[WLAPIManager instance] contributors:^(NSArray* contributors) {
		weakSelf.contributors = [weakSelf processContributors:contributors];
		[weakSelf.spinner stopAnimating];
	} failure:^(NSError *error) {
		[weakSelf.spinner stopAnimating];
		[error show];
	}];
}

- (NSArray*)processContributors:(NSArray*)contributors {
	NSMutableArray* signedUp = [NSMutableArray array];
	NSMutableArray* notSignedUp = [NSMutableArray array];
	for (WLContact* contact in contributors) {
		
		NSMutableArray* users = [contact.users mutableCopy];
		
		[users removeEntry:[WLUser currentUser]];
		
		if (self.wrap.contributor) {
			[users removeEntry:self.wrap.contributor];
		}
		
		NSUInteger index = 0;
		while ([users containsIndex:index]) {
			WLUser* user = users[index];
			if (user.identifier.nonempty) {
				WLContact* _contact = [[WLContact alloc] init];
				_contact.users = @[user];
				[signedUp addObject:_contact];
				[users removeObject:user];
			} else {
				++index;
			}
		}
		
		if ([users count] > 0) {
			contact.users = [users copy];
			[notSignedUp addObject:contact];
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

- (NSMutableArray *)selectedContributors {
	if (!_selectedContributors) {
		_selectedContributors = [NSMutableArray array];
	}
	return _selectedContributors;
}

- (void)setWrap:(WLWrap *)wrap {
	_wrap = wrap;
	[self.selectedContributors setArray:wrap.contributors];
}

- (void)setContributors:(NSArray *)contributors {
	_contributors = contributors;
	[self.tableView reloadData];
}

- (WLUser*)selectedContributor:(WLUser*)contributor {
	return [self.selectedContributors selectObject:^BOOL(id item) {
		return [item isEqualToEntry:contributor];
	}];
}

- (BOOL)isSelectedContributor:(WLUser*)contributor {
	return [self.selectedContributors containsEntry:contributor];
}

#pragma mark - Actions

- (IBAction)back:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)done:(id)sender {
	self.wrap.contributors = (id)[self.wrap.contributors?:@[] entriesByAddingEntries:self.selectedContributors];
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)searchTextChanged:(UITextField *)sender {
	[self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [self.contributors count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSString* searchText = self.searchField.text;
	if (searchText.nonempty) {
		WLContact* contact = self.contributors[section];
		if ([contact.name rangeOfString:searchText options:NSCaseInsensitiveSearch].location == NSNotFound) {
			return 0;
		}
	}
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLContact* contact = self.contributors[indexPath.section];
    WLContactCell* cell = [WLContactCell cellWithContact:contact inTableView:tableView indexPath:indexPath];
	cell.opened = ([contact.users count] > 1 && [self.openedRows containsObject:contact]);
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLContact* contact = self.contributors[indexPath.section];
	if ([contact.users count] > 1 && [self.openedRows containsObject:contact]) {
		return 50 + [contact.users count]*50;
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

- (BOOL)contactCell:(WLContactCell *)cell contributorSelected:(WLUser *)contributor {
	return [self isSelectedContributor:contributor];
}

- (void)contactCell:(WLContactCell *)cell didSelectContributor:(WLUser *)contributor {
	if ([self isSelectedContributor:contributor]) {
		[self.selectedContributors removeObject:[self selectedContributor:contributor]];
	} else {
		[self.selectedContributors addObject:contributor];
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
