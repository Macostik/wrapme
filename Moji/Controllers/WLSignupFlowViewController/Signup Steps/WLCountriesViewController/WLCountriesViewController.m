//
//  WLCountriesViewController.m
//  moji
//
//  Created by Ravenpod on 24.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCountriesViewController.h"
#import "WLCountry.h"
#import "WLCountryCell.h"
#import "NSObject+NibAdditions.h"
#import "StreamViewDataSource.h"

@interface WLCountriesViewController ()

@property (strong, nonatomic) IBOutlet StreamViewDataSource *dataSource;

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
#warning implement scrolling to item
//				[weakSelf.dataSource.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionCenteredVertically];
			}
		}
    });
}

- (WLCountry *)selectedCountry {
    StreamItem* item = self.dataSource.streamView.selectedItem;
    if (item) {
        return [(NSArray*)self.dataSource.items tryAt:item.index.next.value];
    }
    return nil;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

@end
