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
#import "NSDate+Formatting.h"
#import "WLDateHeaderView.h"
#import "WLWrapRequest.h"

@interface WLDatesViewController () <UICollectionViewDataSource, UICollectionViewDelegate, WLDateCellDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView* collectionView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) NSMutableArray* sections;
@property (nonatomic) BOOL completed;

@end

@implementation WLDatesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.sections = [NSMutableArray array];
    
    self.titleLabel.text = self.wrap.name;
    
    if (!self.dates) {
        self.dates = [[WLGroupedSet alloc] init];
        [self.dates addCandies:self.wrap.candies];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self appendDates];
}

- (void)appendDates {
    if (self.completed) return;
    __weak typeof(self)weakSelf = self;
    NSUInteger page = ((self.dates.set.count + 1)/10 + 1);
    NSUInteger count = self.wrap.candies.count;
    [[WLWrapRequest request:self.wrap page:page] send:^(WLWrap* wrap) {
        if (count != wrap.candies.count) {
            [weakSelf.dates addCandies:wrap.candies];
            [weakSelf.collectionView reloadData];
            [weakSelf appendDates];
        } else {
            weakSelf.completed = YES;
        }
    } failure:^(NSError *error) {
    }];
}

- (IBAction)back:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    [self.sections removeAllObjects];
    for (WLGroup* group in self.dates.set) {
        if (![group hasAtLeastOneImage]) {
            continue;
        }
        NSMutableArray* section = nil;
        for (NSMutableArray* _section in self.sections) {
            WLGroup* _group = [_section firstObject];
            if ([[[_group date] stringWithFormat:@"yyyy"] isEqualToString:[[group date] stringWithFormat:@"yyyy"]]) {
                section = _section;
                break;
            }
        }
        if (!section) {
            section = [NSMutableArray arrayWithObject:group];
            [self.sections addObject:section];
        } else {
            [section addObject:group];
        }
    }
    return [self.sections count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSMutableArray* sectionArray = [self.sections objectAtIndex:section];
	return [sectionArray count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* WLDateCellIdentifier = @"WLDateCell";
	WLDateCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:WLDateCellIdentifier forIndexPath:indexPath];
    NSMutableArray* sectionArray = [self.sections objectAtIndex:indexPath.section];
	WLGroup* group = [sectionArray objectAtIndex:indexPath.item];
	cell.item = group;
	cell.delegate = self;
	return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    static NSString* WLDateHeaderViewIdentifier = @"WLDateHeaderView";
    WLDateHeaderView* headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:WLDateHeaderViewIdentifier forIndexPath:indexPath];
    NSMutableArray* sectionArray = [self.sections objectAtIndex:indexPath.section];
	WLGroup* group = [sectionArray objectAtIndex:indexPath.item];
    headerView.dateLabel.text = [[group date] stringWithFormat:@"yyyy"];
    return headerView;
}

#pragma mark - WLDateCellDelegate

- (void)dateCell:(WLDateCell *)cell didSelectGroup:(WLGroup *)group {
    WLCandyViewController *candyController = [WLCandyViewController instantiate];
    candyController.group = group;
    [self.navigationController pushViewController:candyController animated:YES];
}

@end
