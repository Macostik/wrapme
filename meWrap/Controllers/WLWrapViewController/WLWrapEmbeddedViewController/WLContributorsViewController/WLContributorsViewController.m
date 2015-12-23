//
//  WLContributorsViewController.m
//  meWrap
//
//  Created by Ravenpod on 9/5/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLContributorsViewController.h"
#import "WLContributorCell.h"
#import "WLHintView.h"

const static CGFloat WLContributorsVerticalIndent = 48.0f;
const static CGFloat WLContributorsHorizontalIndent = 96.0f;
const static CGFloat WLContributorsMinHeight = 72.0f;

@interface WLContributorsViewController () <WLContributorCellDelegate, EntryNotifying>

@property (strong, nonatomic) IBOutlet StreamDataSource *dataSource;

@property (weak, nonatomic) IBOutlet UIView *addFriendView;

@property (weak, nonatomic) IBOutlet LayoutPrioritizer *restrictedInvitePrioritizer;

@property (strong, nonatomic) NSMutableSet* invitedContributors;

@property (strong, nonatomic) NSMutableSet* removedContributors;

@property (weak, nonatomic) User *contributiorWithOpenedMenu;

@end

@implementation WLContributorsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.invitedContributors = [NSMutableSet set];
    
    self.removedContributors = [NSMutableSet set];
    
    __weak StreamView *streamView = self.dataSource.streamView;
    __weak typeof(self)weakSelf = self;
    self.dataSource.autogeneratedMetrics.nibOwner = self;
    [self.dataSource.autogeneratedMetrics setSizeAt:^CGFloat(StreamItem *item) {
        UIFont *font = [UIFont fontSmall];
        CGFloat textWidth = streamView.width - WLContributorsHorizontalIndent;
        User *contributor = item.entry;
        CGFloat pandingHeight = contributor.isInvited ? [@"sign_up_pending".ls heightWithFont:font width:textWidth] : 0;
        CGFloat phoneHeight = contributor.securePhones.nonempty ? [contributor.securePhones heightWithFont:font width:textWidth] : 0;
        NSString *invitationText = [WLContributorCell invitationHintText:contributor];
        phoneHeight += [invitationText heightWithFont:font width:textWidth];
        
        return MAX(phoneHeight + pandingHeight + WLContributorsVerticalIndent, WLContributorsMinHeight) + 1;
    }];
    
    streamView.contentInset = streamView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 44, 0);
    
    [[Wrap notifier] addReceiver:self];
    
    self.dataSource.items = [self sortedContributors];
    
    [[APIRequest contributors:self.wrap] send:^(id object) {
        weakSelf.dataSource.items = [weakSelf sortedContributors];
    } failure:^(NSError *error) {
        [weakSelf.dataSource reload];
        [error showNonNetworkError];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([self.wrap isFirstCreated]) {
        [WLHintView showInviteHintViewInView:[UIWindow mainWindow] withFocusToView:self.addFriendView];
    }
    if (!self.wrap.contributor.current) {
        self.restrictedInvitePrioritizer.defaultState = !self.wrap.isRestrictedInvite;
    }
}

- (NSArray*)sortedContributors {
    NSMutableArray *contributors = [NSMutableArray arrayWithArray:self.wrap.contributors.allObjects];
    [contributors sortUsingComparator:^NSComparisonResult(User *obj1, User *obj2) {
        if ([obj1 current]) {
            return NSOrderedDescending;
        }
        if ([obj2 current]) {
            return NSOrderedAscending;
        }
        return [obj1.name?:@"" compare:obj2.name?:@""];
    }];
    [contributors removeObjectsInArray:self.removedContributors.allObjects];
    return [contributors copy];
}

#pragma mark - WLContributorCellDelegate

- (void)contributorCell:(WLContributorCell *)cell didRemoveContributor:(User *)contributor {
    AddressBookPhoneNumber *person = [AddressBookPhoneNumber new];
    person.user = contributor;
    NSMutableOrderedSet *contributors = (id)self.dataSource.items;
    [contributors removeObject:contributor];
    [self.dataSource reload];
    [self.removedContributors addObject:contributor];
    __weak typeof(self)weakSelf = self;
    [[APIRequest removeContributors:@[person] wrap:self.wrap] send:^(id object) {
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

- (void)hideMenuForContributor:(User *)contributor {
    if (self.contributiorWithOpenedMenu == contributor) {
        self.contributiorWithOpenedMenu = nil;
        for (StreamItem *item in self.dataSource.streamView.visibleItems) {
            WLContributorCell *cell = (id)item.view;
            if (cell.entry == contributor) {
                [cell setMenuHidden:YES animated:YES];
                break;
            }
        }
    }
}

- (void)contributorCell:(WLContributorCell *)cell didInviteContributor:(User *)contributor completionHandler:(void (^)(BOOL))completionHandler {
    __weak typeof(self)weakSelf = self;
    [[APIRequest resendInvite:self.wrap user:contributor] send:^(id object) {
        if (completionHandler) completionHandler(YES);
        [weakSelf.invitedContributors addObject:contributor];
        [weakSelf enqueueSelector:@selector(hideMenuForContributor:) delay:3.0f];
    } failure:^(NSError *error) {
        [error show];
        if (completionHandler) completionHandler(NO);
    }];
}

- (BOOL)contributorCell:(WLContributorCell *)cell isInvitedContributor:(User *)contributor {
    return [self.invitedContributors containsObject:contributor];
}

- (BOOL)contributorCell:(WLContributorCell *)cell isCreator:(User *)contributor {
    return self.wrap.contributor == contributor;
}

- (void)contributorCell:(WLContributorCell *)cell didToggleMenu:(User *)contributor {
    if (self.contributiorWithOpenedMenu) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideMenuForContributor:) object:self.contributiorWithOpenedMenu];
    }
    
    if (self.contributiorWithOpenedMenu == contributor) {
        self.contributiorWithOpenedMenu = nil;
    } else {
        self.contributiorWithOpenedMenu = contributor;
        for (StreamItem *item in self.dataSource.streamView.visibleItems) {
            WLContributorCell *cell = (id)item.view;
            if (cell.entry != contributor) {
                [cell setMenuHidden:YES animated:YES];
            }
        }
    }
}

- (BOOL)contributorCell:(WLContributorCell *)cell showMenu:(User *)contributor {
    return self.contributiorWithOpenedMenu == contributor;
}

#pragma mark - WLEntryNotifyReceiver

- (BOOL)notifier:(EntryNotifier *)notifier shouldNotifyOnEntry:(Entry *)entry {
    return self.wrap == entry;
}

- (void)notifier:(EntryNotifier *)notifier didUpdateEntry:(Wrap *)wrap event:(enum EntryUpdateEvent)event {
    if (event == EntryUpdateEventContributorsChanged) {
        NSArray *contributors = [self sortedContributors];
        if (![contributors isEqualToArray:(NSArray*)self.dataSource.items]) {
            self.dataSource.items = contributors;
        }
        if (!self.wrap.contributor.current) {
            [self.restrictedInvitePrioritizer setDefaultState:!wrap.isRestrictedInvite animated:[self viewAppeared]];
        }
    }
}

@end
