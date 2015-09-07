//
//  WLCountriesViewController.m
//  meWrap
//
//  Created by Ravenpod on 24.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCountriesViewController.h"
#import "WLCountry.h"
#import "WLCountryCell.h"
#import "NSObject+NibAdditions.h"
#import "WLBasicDataSource.h"

@interface WLCountriesViewController ()

@property (strong, nonatomic) IBOutlet WLBasicDataSource *dataSource;

@end

@implementation WLCountriesViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	__weak typeof(self)weakSelf = self;
    WLCountry* selectedCountry = _selectedCountry;
    run_getting_object(^id {
        return [WLCountry all];
    }, ^(NSMutableOrderedSet* countries) {
        weakSelf.dataSource.items = countries;
		if (selectedCountry) {
			NSUInteger index = [countries indexOfObjectPassingTest:^BOOL(WLCountry* obj, NSUInteger idx, BOOL *stop) {
				return [obj.code isEqualToString:selectedCountry.code];
			}];
			if (index != NSNotFound) {
				[weakSelf.dataSource.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionCenteredVertically];
			}
		}
    });
}

- (WLCountry *)selectedCountry {
    NSIndexPath* indexPath = [[self.dataSource.collectionView indexPathsForSelectedItems] lastObject];
    if (indexPath) {
        return [(NSArray*)self.dataSource.items tryAt:indexPath.item];
    }
    return nil;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

@end
