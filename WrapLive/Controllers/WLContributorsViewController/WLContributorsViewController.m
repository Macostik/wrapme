//
//  WLContributorsViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 25.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLContributorsViewController.h"
#import "WLContributorCell.h"
#import "WLAPIManager.h"
#import "WLAddressBook.h"
#import "WLWrap.h"
#import "NSArray+Additions.h"
#import "WLUser.h"
#import "NSString+Additions.h"

@interface WLContributorsViewController () <UITableViewDataSource, UITableViewDelegate, WLContributorCellDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *searchField;
@property (strong, nonatomic) NSArray* contributors;
@property (strong, nonatomic) NSArray* filteredContributors;
@property (strong, nonatomic) NSMutableArray* selectedContributors;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

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
					WLContact* _contact = [WLContact new];
					_contact.users = users;
					[filteredContributors addObject:_contact];
				}
			}
			weakSelf.filteredContributors = [filteredContributors copy];
		} else {
			weakSelf.filteredContributors = weakSelf.contributors;
		}
        dispatch_async(dispatch_get_main_queue(), ^{
			[weakSelf reloadTableView];
        });
    });
}

- (void)reloadTableView {
	[self.tableView reloadData];
	
	for (NSIndexPath* indexPath in [self.tableView indexPathsForSelectedRows]) {
		[self.tableView deselectRowAtIndexPath:indexPath animated:NO];
	}
	__weak typeof(self)weakSelf = self;
	[self.filteredContributors all:^(WLContact* contact) {
		[contact.users all:^(WLUser* user) {
			if ([weakSelf selectedContributor:user] != nil) {
				NSInteger index = [contact.users indexOfObject:user];
				[weakSelf.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]
											animated:YES
									  scrollPosition:UITableViewScrollPositionNone];
			}
		}];
	}];
}

- (WLUser*)selectedContributor:(WLUser*)contributor {
	return [self.selectedContributors selectObject:^BOOL(id item) {
		return [item isEqualToEntry:contributor];
	}];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [self.filteredContributors count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	WLContact* contact = self.filteredContributors[section];
    return [contact.users count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WLContributorCell* cell = [tableView dequeueReusableCellWithIdentifier:[WLContributorCell reuseIdentifier]];
	WLContact* contact = self.filteredContributors[indexPath.section];
	WLUser* contributor = contact.users[indexPath.row];
    cell.item = contributor;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	WLContact* contact = self.filteredContributors[indexPath.section];
	WLUser* contributor = contact.users[indexPath.row];
	if ([self selectedContributor:contributor] == nil) {
		[self.selectedContributors addObject:contributor];
	}
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	WLContact* contact = self.filteredContributors[indexPath.section];
	WLUser* contributor = contact.users[indexPath.row];
	contributor = [self selectedContributor:contributor];
	if (contributor != nil) {
		[self.selectedContributors removeObject:contributor];
	}
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	[self updateFilteredContributors];
	return YES;
}

@end
