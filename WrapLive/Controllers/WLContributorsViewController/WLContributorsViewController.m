//
//  WLContributorsViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 9/5/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLContributorsViewController.h"
#import "WLBasicDataSource.h"
#import "WLContributorCell.h"
#import "WLAddressBookPhoneNumber.h"
#import "UIFont+CustomFonts.h"

const static CGFloat WLContributorsVerticalIndent = 48.0f;
const static CGFloat WLContributorsHorizontalIndent = 96.0f;
const static CGFloat WLContributorsMinHeight = 72.0f;

@interface WLContributorsViewController () <WLContributorCellDelegate, WLEntryNotifyReceiver>

@property (strong, nonatomic) IBOutlet WLBasicDataSource *dataSource;

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
    __weak UICollectionView *collectionView = self.dataSource.collectionView;
    [self.dataSource setItemSizeBlock:^CGSize(WLUser *contributor, NSUInteger index) {
        UIFont *font = [UIFont preferredFontWithName:WLFontOpenSansLight preset:WLFontPresetSmall];
        CGFloat textWidth = collectionView.width - WLContributorsHorizontalIndent;
        CGFloat height = [contributor.securePhones heightWithFont:font width:textWidth];
        if (contributor.isInvited) {
            NSString *invitationText = contributor.invitationHintText;
            height += [invitationText heightWithFont:font width:textWidth] + 3;
        }
        return CGSizeMake(collectionView.width, MAX(height + WLContributorsVerticalIndent, WLContributorsMinHeight) + 1);
    }];
    
    UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, 44, 0);
    collectionView.contentInset = insets;
    collectionView.scrollIndicatorInsets = insets;
    
    [[WLWrap notifier] addReceiver:self];
}

- (void)setupEditableUserInterface {
    self.dataSource.items = [self sortedContributors];
}

- (NSMutableOrderedSet*)sortedContributors {
    NSMutableOrderedSet *contributors = [self.wrap.contributors mutableCopy];
    [contributors sortUsingComparator:^NSComparisonResult(WLUser *obj1, WLUser *obj2) {
        if ([obj1 isCurrentUser]) {
            return NSOrderedDescending;
        }
        if ([obj2 isCurrentUser]) {
            return NSOrderedAscending;
        }
        return [WLString(obj1.name) compare:WLString(obj2.name)];
    }];
    return contributors;
}

#pragma mark - WLContributorCellDelegate

- (void)contributorCell:(WLContributorCell *)cell didRemoveContributor:(WLUser *)contributor {
    WLAddressBookPhoneNumber *person = [WLAddressBookPhoneNumber new];
    person.user = contributor;
    [self.editSession changeValueForProperty:@"removedContributors" valueBlock:^id(id changedValue) {
        return [changedValue orderedSetByAddingObject:person];
    }];
    NSMutableOrderedSet *contributors = (id)self.dataSource.items;
    [contributors removeObject:contributor];
    [self.dataSource reload];
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

- (BOOL)notifier:(WLEntryNotifier *)notifier shouldNotifyOnEntry:(WLEntry *)entry {
    return self.wrap == entry;
}

- (void)notifier:(WLEntryNotifier *)notifier entryUpdated:(WLWrap *)wrap {
    NSMutableOrderedSet* contributors = [self sortedContributors];
    for (WLAddressBookPhoneNumber* person in [self.editSession changedValueForProperty:@"removedContributors"]) {
        [contributors removeObject:person.user];
    }
    self.dataSource.items = contributors;
}

#pragma mark - Actions

- (void)apply:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    WLUpdateContributorsRequest *updateContributot = [WLUpdateContributorsRequest request:self.wrap];
    updateContributot.contributors = [[self.editSession changedValueForProperty:@"removedContributors"] array];
    [updateContributot send:success failure:failure];
}

@end
