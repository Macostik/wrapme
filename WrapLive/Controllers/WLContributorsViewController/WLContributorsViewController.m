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
#import "WLAddressBookPhoneNumber.h"

@interface WLContributorsViewController () <WLContributorCellDelegate>

@property (strong, nonatomic) IBOutlet WLCollectionViewDataProvider *dataProvider;
@property (strong, nonatomic) IBOutlet WLContributorsViewSection *dataSection;

@property (strong, nonatomic) NSMutableSet* invitedContributors;

@property (strong, nonatomic) NSHashTable* usersWithOpenedMenu;

@end

@implementation WLContributorsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.usersWithOpenedMenu = [NSHashTable weakObjectsHashTable];
    
    self.invitedContributors = [NSMutableSet set];
    
    self.editSession = [[WLEditSession alloc] initWithEntry:self.wrap properties:[NSSet setWithObject:[WLOrderedSetEditSessionProperty property:@"removedContributors"]]];
    // Do any additional setup after loading the view.
    self.dataSection.wrap = self.wrap;
	if (self.wrap.contributedByCurrentUser) {
		[self.dataSection setConfigure:^(WLContributorCell *cell, WLUser* contributor) {
			cell.deletable = ![contributor isCurrentUser];
		}];
    } else {
        [self.dataSection setConfigure:^(WLContributorCell *cell, WLUser* contributor) {
            cell.deletable = NO;
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
    WLAddressBookPhoneNumber *person = [WLAddressBookPhoneNumber new];
    person.user = contributor;
    [self.editSession changeValueForProperty:@"removedContributors" valueBlock:^id(id changedValue) {
        return [changedValue orderedSetByAddingObject:person];
    }];
    [[self.dataSection.entries entries] removeObject:contributor];
    [self.dataSection reload];
}

- (void)contributorCell:(WLContributorCell *)cell didInviteContributor:(WLUser *)contributor completionHandler:(void (^)(BOOL))completionHandler {
    WLResendInviteRequest *request = [WLResendInviteRequest request:self.wrap];
    request.user = contributor;
    __weak typeof(self)weakSelf = self;
    [request send:^(id object) {
        if (completionHandler) completionHandler(YES);
        [weakSelf.invitedContributors addObject:contributor];
    } failure:^(NSError *error) {
        [error show];
        if (completionHandler) completionHandler(NO);
    }];
}

- (BOOL)contributorCell:(WLContributorCell *)cell isInvitedContributor:(WLUser *)contributor {
    return [self.invitedContributors containsObject:contributor];
}

- (BOOL)contributorCell:(WLContributorCell *)cell isCreator:(WLUser *)contributor {
    return self.wrap.contributor == contributor;
}

- (void)contributorCell:(WLContributorCell *)cell didToggleMenu:(WLUser *)contributor {
    if ([self.usersWithOpenedMenu containsObject:contributor]) {
        [self.usersWithOpenedMenu removeObject:contributor];
    } else {
        [self.usersWithOpenedMenu addObject:contributor];
    }
}

- (BOOL)contributorCell:(WLContributorCell *)cell showMenu:(WLUser *)contributor {
    return [self.usersWithOpenedMenu containsObject:contributor];
}

#pragma mark - WLEntryNotifyReceiver

- (WLWrap *)notifierPreferredWrap:(WLEntryNotifier *)notifier {
    return self.wrap;
}

- (void)notifier:(WLEntryNotifier *)notifier wrapUpdated:(WLWrap *)wrap {
    NSMutableOrderedSet* contributors = [self.wrap.contributors mutableCopy];
    for (WLAddressBookPhoneNumber* person in [self.editSession changedValueForProperty:@"removedContributors"]) {
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
