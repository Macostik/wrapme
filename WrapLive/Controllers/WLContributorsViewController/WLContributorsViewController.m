//
//  WLContributorsViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 9/5/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLContributorsViewController.h"
#import "WLCollectionViewDataProvider.h"
#import "WLContributorCell.h"
#import "UIView+Shorthand.h"
#import "UIView+AnimationHelper.h"
#import "WLButton.h"
#import "WLWrapBroadcaster.h"

@interface WLContributorsViewController () <WLContributorCellDelegate>

@property (strong, nonatomic) IBOutlet WLCollectionViewDataProvider *dataProvider;
@property (strong, nonatomic) IBOutlet WLCollectionViewSection *dataSection;

@property (strong, nonatomic) NSMutableOrderedSet* removedContributors;
@property (weak, nonatomic) IBOutlet UIView *bottomView;

@end

@implementation WLContributorsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.removedContributors = [NSMutableOrderedSet orderedSet];
    
    [self.dataSection setConfigure:^(WLContributorCell *cell, WLUser* contributor) {
        cell.deletable = ![contributor isCurrentUser];
    }];
    
    self.dataSection.entries = [self.wrap.contributors mutableCopy];
    self.bottomView.transform = CGAffineTransformMakeTranslation(0, self.bottomView.width);
}

#pragma mark - WLContributorCellDelegate

- (void)contributorCell:(WLContributorCell *)cell didRemoveContributor:(WLUser *)contributor {
    [self.removedContributors addObject:contributor];
    [[self.dataSection.entries entries] removeObject:contributor];
    [self.dataSection reload];
    self.dataProvider.collectionView.contentInset = UIEdgeInsetsMake(0, 0, self.bottomView.width, 0);
    [self.bottomView setTransform:CGAffineTransformIdentity animated:YES];
}

#pragma mark - Actions

- (IBAction)cancel:(id)sender {
    self.dataSection.entries = [self.wrap.contributors mutableCopy];
    self.dataProvider.collectionView.contentInset = UIEdgeInsetsZero;
    [self.bottomView setTransform:CGAffineTransformMakeTranslation(0, self.bottomView.width) animated:YES];
}

- (IBAction)done:(WLButton*)sender {
    sender.loading = YES;
    self.view.userInteractionEnabled = NO;
    __weak typeof(self)weakSelf = self;
    NSMutableOrderedSet* contributors = self.wrap.contributors;
    self.wrap.contributors = [self.dataSection.entries entries];
    [self.wrap update:^(WLWrap *wrap) {
        [weakSelf.navigationController popViewControllerAnimated:YES];
    } failure:^(NSError *error) {
        if ([error isNetworkError] && weakSelf.wrap.uploading) {
            [weakSelf.wrap broadcastChange];
            [weakSelf.navigationController popViewControllerAnimated:YES];
        } else {
            sender.loading = NO;
            [error show];
            weakSelf.wrap.contributors = contributors;
            weakSelf.view.userInteractionEnabled = YES;
        }
    }];
}

@end
