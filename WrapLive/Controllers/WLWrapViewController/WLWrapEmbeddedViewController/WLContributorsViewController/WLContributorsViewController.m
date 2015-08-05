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
#import "WLHintView.h"
#import "WLNavigationHelper.h"
#import "WLLoadingView.h"

const static CGFloat WLContributorsVerticalIndent = 48.0f;
const static CGFloat WLContributorsHorizontalIndent = 96.0f;
const static CGFloat WLContributorsMinHeight = 72.0f;

@interface WLContributorsViewController () <WLContributorCellDelegate, WLEntryNotifyReceiver>

@property (strong, nonatomic) IBOutlet WLBasicDataSource *dataSource;

@property (weak, nonatomic) IBOutlet UIView *addFriendView;

@property (strong, nonatomic) NSMutableSet* invitedContributors;

@property (strong, nonatomic) NSMutableSet* removedContributors;

@property (weak, nonatomic) WLUser* contributiorWithOpenedMenu;

@end

@implementation WLContributorsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [WLLoadingView registerInCollectionView:self.dataSource.collectionView];
    self.dataSource.footerIdentifier = @"WLLoadingView";
    self.dataSource.footerSize = CGSizeMake(self.dataSource.collectionView.width, WLLoadingViewDefaultSize);
    
    self.invitedContributors = [NSMutableSet set];
    
    self.removedContributors = [NSMutableSet set];
    
    __weak UICollectionView *collectionView = self.dataSource.collectionView;
    [self.dataSource setItemSizeBlock:^CGSize(WLUser *contributor, NSUInteger index) {
        UIFont *font = [UIFont preferredDefaultFontWithPreset:WLFontPresetSmall];
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
    
    self.dataSource.items = [self sortedContributors];
    
    __weak typeof(self)weakSelf = self;
    [[WLAPIRequest contributors:self.wrap] send:^(id object) {
        weakSelf.dataSource.footerSize = CGSizeZero;
        weakSelf.dataSource.items = [weakSelf sortedContributors];
    } failure:^(NSError *error) {
        weakSelf.dataSource.footerSize = CGSizeZero;
        [weakSelf.dataSource reload];
        [error showIgnoringNetworkError];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([self.wrap isFirstCreated]) {
        [WLHintView showInviteHintViewInView:[UIWindow mainWindow] withFocusToView:self.addFriendView];
    }
}

- (NSMutableOrderedSet*)sortedContributors {
    NSMutableOrderedSet *contributors = [NSMutableOrderedSet orderedSetWithSet:self.wrap.contributors];
    [contributors sortUsingComparator:^NSComparisonResult(WLUser *obj1, WLUser *obj2) {
        if ([obj1 isCurrentUser]) {
            return NSOrderedDescending;
        }
        if ([obj2 isCurrentUser]) {
            return NSOrderedAscending;
        }
        return [WLString(obj1.name) compare:WLString(obj2.name)];
    }];
    [contributors removeObjectsInArray:self.removedContributors.allObjects];
    return contributors;
}

#pragma mark - WLContributorCellDelegate

- (void)contributorCell:(WLContributorCell *)cell didRemoveContributor:(WLUser *)contributor {
    WLAddressBookPhoneNumber *person = [WLAddressBookPhoneNumber new];
    person.user = contributor;
    NSMutableOrderedSet *contributors = (id)self.dataSource.items;
    [contributors removeObject:contributor];
    [self.dataSource reload];
    [self.removedContributors addObject:contributor];
    __weak typeof(self)weakSelf = self;
    [[WLAPIRequest removeContributors:@[person] wrap:self.wrap] send:^(id object) {
        [weakSelf.removedContributors removeObject:contributor];
        if (weakSelf.contributiorWithOpenedMenu == contributor) {
            weakSelf.contributiorWithOpenedMenu = nil;
        }
    } failure:^(NSError *error) {
        [error show];
        [weakSelf.removedContributors removeObject:contributor];
        weakSelf.dataSource.items = [weakSelf sortedContributors];
    }];
}

- (void)hideMenuForContributor:(WLUser*)contributor {
    if (self.contributiorWithOpenedMenu == contributor) {
        self.contributiorWithOpenedMenu = nil;
        for (WLContributorCell *cell in [self.dataSource.collectionView visibleCells]) {
            if (cell.entry == contributor) {
                [cell setMenuHidden:YES animated:YES];
                break;
            }
        }
    }
}

- (void)contributorCell:(WLContributorCell *)cell didInviteContributor:(WLUser *)contributor completionHandler:(void (^)(BOOL))completionHandler {
    __weak typeof(self)weakSelf = self;
    [[WLAPIRequest resendInvite:self.wrap user:contributor] send:^(id object) {
        if (completionHandler) completionHandler(YES);
        [weakSelf.invitedContributors addObject:contributor];
        [weakSelf enqueueSelectorPerforming:@selector(hideMenuForContributor:) afterDelay:3.0f];
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
    if (self.contributiorWithOpenedMenu) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideMenuForContributor:) object:self.contributiorWithOpenedMenu];
    }
    
    if (self.contributiorWithOpenedMenu == contributor) {
        self.contributiorWithOpenedMenu = nil;
    } else {
        self.contributiorWithOpenedMenu = contributor;
        for (WLContributorCell *cell in [self.dataSource.collectionView visibleCells]) {
            if (cell.entry != contributor) {
                [cell setMenuHidden:YES animated:YES];
            }
        }
    }
}

- (BOOL)contributorCell:(WLContributorCell *)cell showMenu:(WLUser *)contributor {
    return self.contributiorWithOpenedMenu == contributor;
}

#pragma mark - WLEntryNotifyReceiver

- (BOOL)notifier:(WLEntryNotifier *)notifier shouldNotifyOnEntry:(WLEntry *)entry {
    return self.wrap == entry;
}

- (void)notifier:(WLEntryNotifier *)notifier didUpdateEntry:(WLWrap *)wrap {
    self.dataSource.items = [self sortedContributors];
}

@end
