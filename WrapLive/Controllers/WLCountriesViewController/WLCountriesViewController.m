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
    run_getting_object(^id {
        return [WLCountry all];
    }, ^(NSMutableOrderedSet* countries) {
        weakSelf.dataSection.entries = countries;
		if (weakSelf.selectedCountry) {
			NSUInteger index = [countries indexOfObjectPassingTest:^BOOL(WLCountry* obj, NSUInteger idx, BOOL *stop) {
				return [obj.code isEqualToString:weakSelf.selectedCountry.code];
			}];
			if (index != NSNotFound) {
				[weakSelf.dataSection.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
			}
		}
    });
    [self.dataSection setSelection:^(id item){
        weakSelf.selectedCountry = item;
        [weakSelf.dataSection reload];
        if (weakSelf.selectionBlock) {
            weakSelf.selectionBlock(item);
        }
    }];
    
    [self.dataSection setConfigure:^(WLCountryCell* cell, WLCountry* item) {
        cell.backgroundColor = [item.code isEqualToString:weakSelf.selectedCountry.code] ? [UIColor gray:230] : [UIColor whiteColor];
    }];
}

@end
