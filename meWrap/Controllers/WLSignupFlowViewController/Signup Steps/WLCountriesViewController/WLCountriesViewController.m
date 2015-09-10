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
#import "StreamDataSource.h"

@interface WLCountriesViewController ()

@property (strong, nonatomic) IBOutlet StreamDataSource *dataSource;

@end

@implementation WLCountriesViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	__weak typeof(self)weakSelf = self;
    WLCountry* selectedCountry = _selectedCountry;
    
    [self.dataSource.autogeneratedMetrics setSelection:^(StreamItem *item, id entry) {
        if (weakSelf.selectionBlock) {
            weakSelf.selectionBlock(entry);
        }
    }];
    
    [self.dataSource setDidLayoutItemBlock:^(StreamItem *item) {
        if ([[(WLCountry*)item.entry code] isEqualToString:selectedCountry.code]) {
            item.selected = YES;
        }
    }];
    
    run_getting_object(^id {
        return [WLCountry all];
    }, ^(NSMutableOrderedSet* countries) {
        weakSelf.dataSource.items = countries;
		[weakSelf.dataSource.streamView scrollToItem:weakSelf.dataSource.streamView.selectedItem animated:NO];
    });
}

- (WLCountry *)selectedCountry {
    StreamItem* item = self.dataSource.streamView.selectedItem;
    if (item) {
        return [self.dataSource.items tryAt:item.position.index];
    }
    return nil;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

@end
