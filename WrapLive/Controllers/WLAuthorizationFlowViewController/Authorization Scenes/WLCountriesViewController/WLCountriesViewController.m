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
#import "WLCollectionViewDataProvider.h"
#import "WLCollectionViewSection.h"
#import "UIColor+CustomColors.h"

@interface WLCountriesViewController ()

@property (strong, nonatomic) IBOutlet WLCollectionViewDataProvider *dataProvider;
@property (strong, nonatomic) IBOutlet WLCollectionViewSection *dataSection;

@end

@implementation WLCountriesViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	__weak typeof(self)weakSelf = self;
    WLCountry* selectedCountry = _selectedCountry;
    run_getting_object(^id {
        return [WLCountry all];
    }, ^(NSMutableOrderedSet* countries) {
        weakSelf.dataSection.entries = countries;
		if (selectedCountry) {
			NSUInteger index = [countries indexOfObjectPassingTest:^BOOL(WLCountry* obj, NSUInteger idx, BOOL *stop) {
				return [obj.code isEqualToString:selectedCountry.code];
			}];
			if (index != NSNotFound) {
				[weakSelf.dataSection.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionCenteredVertically];
			}
		}
    });
}

- (WLCountry *)selectedCountry {
    NSIndexPath* indexPath = [[self.dataSection.collectionView indexPathsForSelectedItems] lastObject];
    if (indexPath) {
        return [self.dataSection.entries.entries tryObjectAtIndex:indexPath.item];
    }
    return nil;
}

@end
