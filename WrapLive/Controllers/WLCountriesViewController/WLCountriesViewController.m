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
#import "WLBlocks.h"
#import "WLCollectionViewDataProvider.h"
#import "WLCollectionViewSection.h"

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
    });
    self.dataSection.selection = self.selectionBlock;
}

#pragma mark - User Actions

- (IBAction)cencel:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

@end
