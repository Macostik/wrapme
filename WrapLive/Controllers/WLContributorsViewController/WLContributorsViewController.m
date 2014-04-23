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
		weakSelf.contributors = [contributors arrayByRemovingCurrentUserAndUser:weakSelf.wrap.contributor];
		[weakSelf.spinner stopAnimating];
	} failure:^(NSError *error) {
		[weakSelf.spinner stopAnimating];
		[error show];
	}];
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
		if (text.length > 0) {
			NSPredicate* predicate = [NSPredicate predicateWithFormat:@"name CONTAINS[c] %@", text];
			weakSelf.filteredContributors = [weakSelf.contributors filteredArrayUsingPredicate:predicate];
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
	
	for (WLUser* contributor in self.filteredContributors) {
		if ([self selectedContributor:contributor] != nil) {
			NSInteger index = [self.filteredContributors indexOfObject:contributor];
			[self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]
										animated:YES
								  scrollPosition:UITableViewScrollPositionNone];
		}
	}
}

- (WLUser*)selectedContributor:(WLUser*)contributor {
	for (WLUser* _contributor in self.selectedContributors) {
		if ([_contributor isEqualToUser:contributor]) {
			return _contributor;
		}
	}
	return nil;
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
    WLContributorCell* cell = [tableView dequeueReusableCellWithIdentifier:[WLContributorCell reuseIdentifier]];
	WLUser* contributor = [self.filteredContributors objectAtIndex:indexPath.row];
    cell.item = contributor;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	WLUser* contributor = self.filteredContributors[indexPath.row];
	if ([self selectedContributor:contributor] == nil) {
		[self.selectedContributors addObject:contributor];
	}
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	WLUser* contributor = [self selectedContributor:self.filteredContributors[indexPath.row]];
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
