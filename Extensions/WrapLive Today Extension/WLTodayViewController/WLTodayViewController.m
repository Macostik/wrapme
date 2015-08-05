//
//  WLTodayViewController.m
//  WLTodayExtension
//
//  Created by Yura Granchenko on 11/27/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import "WLTodayCandyCell.h"
#import "WLTodayCommentCell.h"

static NSString *const WLTodayCandyCellIdentifier = @"WLTodayCandyCell";
static NSString *const WLTodayCommentCellIdentifier = @"WLTodayCommentCell";
static NSString *const WLLessButtonKey = @"Less MOJI stories";
static NSString *const WLMoreButtonKey = @"More MOJI stories";
static CGFloat WLMaxRow = 6;
static CGFloat WLMinRow = 3;

typedef NS_ENUM(NSUInteger, WLTodayViewState) {
    WLTodayViewStateUnauthorized,
    WLTodayViewStateLoading,
    WLTodayViewStateShowMore,
    WLTodayViewStateShowLess,
    WLTodayViewStateNoFooter
};

@interface WLTodayViewController () <NCWidgetProviding, WLEntryNotifyReceiver>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *moreButton;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (strong, nonatomic) NSOrderedSet *contributions;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property (nonatomic) WLTodayViewState state;

@property (strong, nonatomic) UIView* tableFooterView;

@end

@implementation WLTodayViewController

- (void)dealloc {
    [self.tableView removeObserver:self forKeyPath:@"contentSize" context:NULL];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.estimatedRowHeight = 50.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self fetchContributions];
    [self updateExtensionWithResult:nil];
    
    [self.tableView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:NULL];
    
    self.tableFooterView = self.tableView.tableFooterView;
}

- (void)setState:(WLTodayViewState)state {
    _state = state;
    
    switch (state) {
        case WLTodayViewStateUnauthorized:
            if (!self.tableView.tableFooterView) self.tableView.tableFooterView = self.tableFooterView;
            self.signUpButton.hidden = NO;
            self.moreButton.hidden = YES;
            [self.spinner stopAnimating];
            break;
        case WLTodayViewStateLoading:
            if (!self.tableView.tableFooterView) self.tableView.tableFooterView = self.tableFooterView;
            self.signUpButton.hidden = YES;
            self.moreButton.hidden = YES;
            [self.spinner startAnimating];
            break;
        case WLTodayViewStateShowMore:
            if (!self.tableView.tableFooterView) self.tableView.tableFooterView = self.tableFooterView;
            [self.moreButton setTitle:WLMoreButtonKey forState:UIControlStateNormal];
            self.signUpButton.hidden = YES;
            self.moreButton.hidden = NO;
            [self.spinner stopAnimating];
            break;
        case WLTodayViewStateShowLess:
            if (!self.tableView.tableFooterView) self.tableView.tableFooterView = self.tableFooterView;
            [self.moreButton setTitle:WLLessButtonKey forState:UIControlStateNormal];
            self.signUpButton.hidden = YES;
            self.moreButton.hidden = NO;
            [self.spinner stopAnimating];
            break;
        case WLTodayViewStateNoFooter:
            self.tableView.tableFooterView = nil;
            break;
        default:
            break;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentSize"]) {
        [self setPreferredContentSize:CGSizeMake(0.0, MAX(50, self.tableView.contentSize.height))];
    }
}

- (NCUpdateResult)fetchContributions {
    NSOrderedSet *contributions = [WLContribution recentContributions:WLRecentContributionsDefaultLimit];
    NCUpdateResult updateResult = [self.contributions isEqualToOrderedSet:contributions] ? NCUpdateResultNoData : NCUpdateResultNewData;
    self.contributions = contributions;
    return updateResult;
}

- (void)setContributions:(NSOrderedSet *)contributions {
    _contributions = contributions;
    if (contributions.count <= WLMinRow) {
        self.state = WLTodayViewStateNoFooter;
    } else {
        self.state = WLTodayViewStateShowMore;
    }
    [self.tableView reloadData];
}

#pragma mark - NCWidgetProviding

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    [self updateExtensionWithResult:completionHandler];
}

- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets {
    return UIEdgeInsetsZero;
}

- (void)updateExtensionWithResult:(void(^)(NCUpdateResult))result {
    if (![[WLAuthorization currentAuthorization:NO] canAuthorize]) {
        self.state = WLTodayViewStateUnauthorized;
        if (result) result(NCUpdateResultNoData);
        return;
    }
    NCUpdateResult status = [self fetchContributions];
    if (result) result(status);
}

- (IBAction)moreStories:(UIButton *)sender {
    self.state = (self.state == WLTodayViewStateShowLess) ? WLTodayViewStateShowMore : WLTodayViewStateShowLess;
    [self.tableView reloadData];
}

- (IBAction)singUpClick:(id)sender {
    [self.extensionContext openURL:[NSURL WLURLWithPath:@"/"] completionHandler:NULL];
}

#pragma mark - UITableViewDelegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return Smoothstep(0, self.state == WLTodayViewStateShowLess ? WLMaxRow : WLMinRow, [self.contributions count]);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WLContribution *contribution = self.contributions[indexPath.row];
    if ([contribution isKindOfClass:[WLComment class]]) {
        WLTodayContributionCell *cell = [tableView dequeueReusableCellWithIdentifier:WLTodayCommentCellIdentifier forIndexPath:indexPath];
        cell.contribution = contribution;
        return cell;
    } else {
        WLTodayContributionCell *cell = [tableView dequeueReusableCellWithIdentifier:WLTodayCandyCellIdentifier forIndexPath:indexPath];
        cell.contribution = contribution;
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WLContribution *contribution = self.contributions[indexPath.row];
    if (contribution.identifier != nil) {
        NSURL *url = nil;
        if ([contribution isKindOfClass:[WLComment class]]) {
            url = [NSURL WLURLForRemoteEntryWithKey:WLCommentKey identifier:contribution.identifier];
        } else {
            url = [NSURL WLURLForRemoteEntryWithKey:WLCandyKey identifier:contribution.identifier];
        }
        [self.extensionContext openURL:url completionHandler:NULL];
    }
}

@end
