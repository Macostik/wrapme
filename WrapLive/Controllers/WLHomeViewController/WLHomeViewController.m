//
//  WLHomeViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 19.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLHomeViewController.h"
#import "WLWrapCell.h"
#import "WLWrap.h"
#import "WLWrapEntry.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "WLAPIManager.h"

@interface WLHomeViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UIView *headerView;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *headerEntryViews;
@property (weak, nonatomic) IBOutlet UIView *headerWrapView;
@property (weak, nonatomic) IBOutlet UILabel *headerWrapNameLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *noWrapsView;

@property (strong, nonatomic) NSArray* wraps;

@end

@implementation WLHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	self.tableView.hidden = YES;
	self.noWrapsView.hidden = YES;
	
	__weak typeof(self)weakSelf = self;
	[[WLAPIManager instance] wraps:^(id object) {
		weakSelf.wraps = object;
	} failure:^(NSError *error) {
	}];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)setWraps:(NSArray *)wraps {
	_wraps = wraps;
	
	BOOL hasWraps = [_wraps count] > 0;
	self.tableView.hidden = !hasWraps;
	self.noWrapsView.hidden = hasWraps;
	if (hasWraps) {
		[self updateHeaderView];
	}
	[self.tableView reloadData];
}

- (void)updateHeaderView {
	WLWrap* wrap = [self.wraps lastObject];
	self.headerWrapNameLabel.text = wrap.name;
	[wrap.entries enumerateObjectsUsingBlock:^(WLWrapEntry* entry, NSUInteger idx, BOOL *stop) {
		if (idx < [self.headerEntryViews count]) {
			UIImageView* imageView = [self.headerEntryViews objectAtIndex:idx];
			imageView.image = nil;
			[imageView setImageWithURL:[NSURL URLWithString:entry.cover]];
		} else {
			*stop = YES;
		}
	}];
}

#pragma mark - <UITableViewDataSource, UITableViewDelegate>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.wraps count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString* wrapCellIdentifier = @"WLWrapCell";
	WLWrapCell* cell = [tableView dequeueReusableCellWithIdentifier:wrapCellIdentifier
													   forIndexPath:indexPath];
	cell.item = [self.wraps objectAtIndex:indexPath.row];
	return cell;
}

@end
