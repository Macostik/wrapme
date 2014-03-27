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

@end

@implementation WLContributorsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	__weak typeof(self)weakSelf = self;
	[WLAddressBook users:^(NSArray *users) {
		weakSelf.contributors = users;
	} failure:^(NSError *error) {
		
	}];
}

- (void)setContributors:(NSArray *)contributors {
	_contributors = contributors;
	
	[self.tableView reloadData];
	
	for (WLUser* contributor in contributors) {
		for (WLUser* _contributor in self.wrap.contributors) {
			if ([_contributor isEqualToUser:contributor]) {
				NSInteger index = [contributors indexOfObject:contributor];
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
	self.wrap.contributors = [[self.tableView indexPathsForSelectedRows] map:^id(NSIndexPath* indexPath) {
		return self.contributors[indexPath.row];
	}];
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.contributors count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WLContributorCell* cell = [tableView dequeueReusableCellWithIdentifier:[WLContributorCell reuseIdentifier]];
	WLUser* contributor = [self.contributors objectAtIndex:indexPath.row];
    cell.item = contributor;
    return cell;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

@end
