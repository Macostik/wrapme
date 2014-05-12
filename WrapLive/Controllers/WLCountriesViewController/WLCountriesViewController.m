//
//  WLCountriesViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 24.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCountriesViewController.h"
#import "WLCountry.h"
#import "WLCountryCell.h"
#import "NSObject+NibAdditions.h"
#import "WLBlocks.h"

@interface WLCountriesViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSArray* countries;

@end

@implementation WLCountriesViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	__weak typeof(self)weakSelf = self;
	run_with_completion(^{
		weakSelf.countries = [WLCountry getAllCountries];
	}, ^{
		weakSelf.tableView.contentInset = UIEdgeInsetsZero;
		[weakSelf.tableView reloadData];
	});
}

#pragma mark - User Actions

- (IBAction)cencel:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.countries count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WLCountryCell* cell = [tableView dequeueReusableCellWithIdentifier:[WLCountryCell reuseIdentifier]];
    if (!cell) {
        cell = [WLCountryCell loadFromNib];
    }
    cell.item = [self.countries objectAtIndex:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	WLCountry* country = [self.countries objectAtIndex:indexPath.row];
	self.selectionBlock(country);
	[self.navigationController popViewControllerAnimated:YES];
}

@end
