//
//  WLContributorsViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 9/5/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLContributorsViewController.h"
#import "WLCollectionViewDataProvider.h"
#import "WLContributorsViewSection.h"
#import "WLContributorCell.h"
#import "WLUpdateContributorsRequest.h"
#import "WLPerson.h"
#import "WLEntryNotifier.h"

@interface WLContributorsViewController () <WLContributorCellDelegate>

@property (strong, nonatomic) IBOutlet WLCollectionViewDataProvider *dataProvider;
@property (strong, nonatomic) IBOutlet WLContributorsViewSection *dataSection;

@end

@implementation WLContributorsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.editSession = [[WLEditSession alloc] initWithEntry:self.wrap properties:[NSSet setWithObject:[WLOrderedSetEditSessionProperty property:@"removedContributors"]]];
    // Do any additional setup after loading the view.
    
	if (self.wrap.contributedByCurrentUser) {
		[self.dataSection setConfigure:^(WLContributorCell *cell, WLUser* contributor) {
			cell.deletable = ![contributor isCurrentUser];
		}];
	}
    
    UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, 44, 0);
    self.dataProvider.collectionView.contentInset = insets;
    self.dataProvider.collectionView.scrollIndicatorInsets = insets;
    
    [[WLWrap notifier] addReceiver:self];
}

- (void)setupEditableUserInterface {
    self.dataSection.entries = [self.wrap.contributors mutableCopy];
}

#pragma mark - WLContributorCellDelegate

- (void)contributorCell:(WLContributorCell *)cell didRemoveContributor:(WLUser *)contributor {
    WLPerson *person = [WLPerson new];
    person.user = contributor;
    [self.editSession changeValueForProperty:@"removedContributors" valueBlock:^id(id changedValue) {
        return [changedValue orderedSetByAddingObject:person];
    }];
    [[self.dataSection.entries entries] removeObject:contributor];
    [self.dataSection reload];
}

- (BOOL)contributorCell:(WLContributorCell *)cell isCreator:(WLUser *)contributor {
    return self.wrap.contributor == contributor;
}

#pragma mark - WLEntryNotifyReceiver

- (WLWrap *)notifierPreferredWrap:(WLEntryNotifier *)notifier {
    return self.wrap;
}

- (void)notifier:(WLEntryNotifier *)notifier wrapUpdated:(WLWrap *)wrap {
    NSMutableOrderedSet* contributors = [self.wrap.contributors mutableCopy];
    for (WLPerson* person in [self.editSession changedValueForProperty:@"removedContributors"]) {
        [contributors removeObject:person.user];
    }
    self.dataSection.entries = contributors;
}

#pragma mark - Actions

- (void)apply:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    WLUpdateContributorsRequest *updateContributot = [WLUpdateContributorsRequest request:self.wrap];
    updateContributot.contributors = [[self.editSession changedValueForProperty:@"removedContributors"] array];
    [updateContributot send:success failure:failure];
}

@end
