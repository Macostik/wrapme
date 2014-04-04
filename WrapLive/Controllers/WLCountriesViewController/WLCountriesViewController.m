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

@interface WLCountriesViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) void (^completionBlock) (WLCountry* country);
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSArray* countries;

@end

@implementation WLCountriesViewController

static WLCountriesViewController* _controller = nil;

+ (void)show:(void (^)(WLCountry *))completion {
	_controller = [[WLCountriesViewController alloc] init];
	[_controller show:completion];
}

- (void)show:(void (^)(WLCountry *))completion {
	self.completionBlock = completion;
	UIView* superview = [UIApplication sharedApplication].keyWindow;
	self.view.frame = superview.bounds;
	self.tableView.superview.transform = CGAffineTransformMakeTranslation(0, superview.frame.size.height);
	[superview addSubview:self.view];
	self.view.alpha = 0.0f;
	
	[UIView animateWithDuration:0.5f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.tableView.superview.transform = CGAffineTransformIdentity;
		self.view.alpha = 1.0f;
	} completion:^(BOOL finished) {
	}];
	
	self.countries = [WLCountry getAllCountries];
	
	self.tableView.rowHeight = roundf(self.tableView.frame.size.height/6);
	[self.tableView reloadData];
}

- (void)hide {
	[UIView animateWithDuration:0.3f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.tableView.superview.transform = CGAffineTransformMakeTranslation(0, self.view.superview.frame.size.height);
		self.view.alpha = 0.0f;
	} completion:^(BOOL finished) {
		[self.view removeFromSuperview];
		_controller = nil;
	}];
}

#pragma mark - User Actions

- (IBAction)cencel:(id)sender {
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	WLCountry* country = [self.countries objectAtIndex:indexPath.row];
	self.completionBlock(country);
	[self hide];
}

@end
