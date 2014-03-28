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
	NSMutableArray* candies = [self.wrap.candies mutableCopy];
	
	NSMutableArray* wrapDays = [NSMutableArray array];
	
	while ([candies count] > 0) {
		WLCandy* candy = [candies firstObject];
		NSDate* startDate = [candy.modified beginOfDay];
		NSDate* endDate = [candy.modified endOfDay];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(modified >= %@) AND (modified <= %@)", startDate, endDate];
		NSArray *dayCandies = [candies filteredArrayUsingPredicate:predicate];
		WLWrapDay * wrapDay = [WLWrapDay new];
		wrapDay.modifiedString = [candy.modified stringWithFormat:@"MMM dd, YYYY"];
		wrapDay.candies = dayCandies;
		[wrapDays addObject:wrapDay];
		[candies removeObjectsInArray:dayCandies];
	}
	
	self.wrapDays = [wrapDays copy];
	
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
