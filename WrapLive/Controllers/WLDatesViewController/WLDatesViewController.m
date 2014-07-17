//
//  WLDatesViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLDatesViewController.h"
#import "WLDateCell.h"
#import "WLCandyViewController.h"
#import "WLNavigation.h"

@interface WLDatesViewController () <UICollectionViewDataSource, UICollectionViewDelegate, WLDateCellDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView* collectionView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation WLDatesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.titleLabel.text = self.wrap.name;
    
    if (!self.dates) {
        self.dates = [[WLGroupedSet alloc] init];
        [self.dates addCandies:self.wrap.candies];
    }
}

- (IBAction)back:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return [self.dates.set count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* WLDateCellIdentifier = @"WLDateCell";
	WLDateCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:WLDateCellIdentifier forIndexPath:indexPath];
	WLGroup* group = [self.dates.set objectAtIndex:indexPath.item];
	cell.item = group;
	cell.delegate = self;
	return cell;
}

#pragma mark - WLDateCellDelegate

- (void)dateCell:(WLDateCell *)cell didSelectGroup:(WLGroup *)group {
    WLCandyViewController *candyController = [WLCandyViewController instantiate];
    candyController.group = group;
    [self.navigationController pushViewController:candyController animated:YES];
}

@end
