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

@property (strong, nonatomic) NSMutableSet* removedContributors;

@property (weak, nonatomic) WLUser* contributiorWithOpenedMenu;

@end

@implementation WLContributorsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.invitedContributors = [NSMutableSet set];
    
    self.removedContributors = [NSMutableSet set];
    
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
    WLUpdateContributorsRequest *updateContributot = [WLUpdateContributorsRequest request:self.wrap];
    updateContributot.contributors = @[person];
    __weak typeof(self)weakSelf = self;
    [updateContributot send:^(id object) {
        [weakSelf.removedContributors removeObject:contributor];
    } failure:^(NSError *error) {
        [error show];
        [weakSelf.removedContributors removeObject:contributor];
        weakSelf.dataSource.items = [weakSelf sortedContributors];
    }];
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

- (void)notifier:(WLEntryNotifier *)notifier entryUpdated:(WLWrap *)wrap {
    self.dataSource.items = [self sortedContributors];
}

@end
