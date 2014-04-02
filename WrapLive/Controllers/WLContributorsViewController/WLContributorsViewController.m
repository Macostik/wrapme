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

@end

@implementation WLContributorsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	__weak typeof(self)weakSelf = self;
	[[WLAPIManager instance] contributors:^(id object) {
		weakSelf.contributors = object;
	} failure:^(NSError *error) {
	}];
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
	for (WLUser* contributor in self.filteredContributors) {
		for (WLUser* _contributor in self.wrap.contributors) {
			if ([_contributor isEqualToUser:contributor]) {
				NSInteger index = [self.filteredContributors indexOfObject:contributor];
				[self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
			}
		}
	}
}

#pragma mark - Actions

- (IBAction)back:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)done:(id)sender {
	self.wrap.contributors = (id)[[self.tableView indexPathsForSelectedRows] map:^id(NSIndexPath* indexPath) {
		return self.filteredContributors[indexPath.row];
	}];
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

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	[self updateFilteredContributors];
	return YES;
}

@end
