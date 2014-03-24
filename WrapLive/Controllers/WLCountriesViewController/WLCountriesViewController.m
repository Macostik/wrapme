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

@interface WLCountriesViewController ()

@property (strong, nonatomic) void (^completionBlock) (WLCountry* country);
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSArray* countries;

@end

@implementation WLCountriesViewController

+ (void)load {
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[WLCountriesViewController show:^(WLCountry *country) {
			
		}];
	});
}

static WLCountriesViewController* _controller = nil;

+ (void)show:(void (^)(WLCountry *))completion {
	_controller = [[WLCountriesViewController alloc] init];
	[_controller show:completion];
}

- (void)show:(void (^)(WLCountry *))completion {
	self.completionBlock = completion;
	UIView* superview = [UIApplication sharedApplication].keyWindow;
	self.view.frame = superview.bounds;
	[superview addSubview:self.view];
	
	NSArray* json = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"CountryCodes_sorted" ofType:@"json"]] options:NSJSONReadingAllowFragments error:NULL];
	
	self.countries = [WLCountry arrayOfModelsFromDictionaries:json];
	
	self.tableView.rowHeight = roundf(self.tableView.frame.size.height/6);
	[self.tableView reloadData];
}

- (void)hide {
	[self.view removeFromSuperview];
	_controller = nil;
}

#pragma mark - User Actions

- (IBAction)cencel:(id)sender {
	[self hide];
}

- (IBAction)done:(id)sender {
	NSIndexPath* indexPath = [self.tableView indexPathForSelectedRow];
	if (indexPath) {
		WLCountry* country = [self.countries objectAtIndex:indexPath.row];
		self.completionBlock(country);
	}
	[self hide];
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

@end
