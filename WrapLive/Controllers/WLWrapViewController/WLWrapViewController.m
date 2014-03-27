//
//  WLWrapViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapViewController.h"
#import "WLWrap.h"
#import "WLWrapCandiesCell.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "WLCandy.h"
#import "NSDate+Formatting.h"
#import "WLWrapDay.h"

@interface WLWrapViewController ()

@property (strong, nonatomic) IBOutlet UITableView* tableView;
@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *contributorsLabel;
@property (strong, nonatomic) NSMutableDictionary * candies;
@property (strong, nonatomic) NSArray * dateRowKeys;
@property (strong, nonatomic) NSMutableArray * wrapDays;

@end

@implementation WLWrapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	[self.coverView setImageWithURL:[NSURL URLWithString:self.wrap.cover]];
	self.nameLabel.text = self.wrap.name;
	
	[self sortCandiesInWrap];
}

- (void) sortCandiesInWrap {
	self.wrapDays = [NSMutableArray array];
	self.candies = [NSMutableDictionary dictionary];
	NSMutableArray * unsortedWrapDays = [NSMutableArray array];
	for (WLCandy * candy in self.wrap.candies) {
		NSString * modified = [candy.modified stringWithFormat:@"MMM dd, YYYY"];
		NSMutableArray *candiesInWrapDay = nil;
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF == %@", modified];
		NSArray *foundSection = [unsortedWrapDays filteredArrayUsingPredicate:predicate];
		if (foundSection.count) {
            candiesInWrapDay = [self.candies objectForKey:modified];
        } else {
			candiesInWrapDay = [NSMutableArray array];
            [unsortedWrapDays addObject:modified];
        }
		[candiesInWrapDay addObject:candy];
		[self.candies setObject:candiesInWrapDay forKey:modified];
	}
	self.dateRowKeys = [NSArray arrayWithArray:unsortedWrapDays];
	
	for (NSString * modifiedString in self.dateRowKeys) {
		WLWrapDay * wrapDay = [WLWrapDay new];
		wrapDay.modifiedString = modifiedString;
		wrapDay.candies = [self.candies objectForKey:modifiedString];
		[self.wrapDays addObject:wrapDay];
	}
	[self.tableView reloadData];
}

- (IBAction)back:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.wrapDays.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WLWrapCandiesCell* cell = [tableView dequeueReusableCellWithIdentifier:[WLWrapCandiesCell reuseIdentifier]];
    WLWrapDay * selectedWrapDay = [self.wrapDays objectAtIndex:indexPath.row];
	cell.item = selectedWrapDay;
    return cell;
}

@end
