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

@interface WLContributorsViewController () <UITableViewDataSource, UITableViewDelegate, WLContactCellDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *searchField;
@property (strong, nonatomic) NSArray* contributors;
@property (strong, nonatomic) NSArray* filteredContributors;
@property (strong, nonatomic) NSMutableArray* selectedContributors;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, strong) NSMutableSet* openedRows;

@end

@implementation WLContributorsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	[self.spinner startAnimating];
	__weak typeof(self)weakSelf = self;
	[[WLAPIManager instance] contributors:^(NSArray* contributors) {
		weakSelf.contributors = [weakSelf clearContributors:contributors];
		[weakSelf.spinner stopAnimating];
	} failure:^(NSError *error) {
		[weakSelf.spinner stopAnimating];
		[error show];
	}];
}

- (NSArray*)clearContributors:(NSArray*)contributors {
	for (WLContact* contact in contributors) {
		contact.users = [contact.users arrayByRemovingCurrentUserAndUser:self.wrap.contributor];
	}
	return contributors;
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
	[self updateFilteredContributors];
}

- (void)updateFilteredContributors {
	NSString* text = self.searchField.text;
	__weak typeof(self)weakSelf = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		if (text.nonempty) {
			NSMutableArray* filteredContributors = [NSMutableArray array];
			for (WLContact* contact in weakSelf.contributors) {
				NSPredicate* predicate = [NSPredicate predicateWithFormat:@"name CONTAINS[c] %@", text];
				NSArray* users = [contact.users filteredArrayUsingPredicate:predicate];
				if ([users count] > 0) {
					[filteredContributors addObject:contact];
				}
			}
			weakSelf.filteredContributors = [filteredContributors copy];
		} else {
			weakSelf.filteredContributors = weakSelf.contributors;
		}
        dispatch_async(dispatch_get_main_queue(), ^{
			[weakSelf.tableView reloadData];
        });
    });
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
	NSMutableArray* contributors = [NSMutableArray arrayWithArray:self.wrap.contributors];
	for (WLUser *user in self.selectedContributors) {
		[contributors addUniqueObject:user equality:[WLUser equalityBlock]];
	}
	self.wrap.contributors = [contributors copy];
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)searchTextChanged:(UITextField *)sender {
	[self updateFilteredContributors];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.filteredContributors count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLContact* contact = self.filteredContributors[indexPath.row];
    WLContactCell* cell = [WLContactCell cellWithContact:contact inTableView:tableView indexPath:indexPath];
	cell.opened = ([contact.users count] > 1 && [self.openedRows containsObject:contact]);
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLContact* contact = self.filteredContributors[indexPath.row];
	if ([contact.users count] > 1 && [self.openedRows containsObject:contact]) {
		return 50 + [contact.users count]*50;
	}
	return 50;
}

#pragma mark - WLContactCellDelegate

- (BOOL)contactCell:(WLContactCell *)cell contributorSelected:(WLUser *)contributor {
	return [self isSelectedContributor:contributor];
}

- (void)contactCell:(WLContactCell *)cell didSelectContributor:(WLUser *)contributor {
	if ([self isSelectedContributor:contributor]) {
		[self.selectedContributors removeObject:contributor];
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
	[self updateFilteredContributors];
	return YES;
}

@end
