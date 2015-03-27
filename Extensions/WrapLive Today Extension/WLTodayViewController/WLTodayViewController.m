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
static NSString *const WLLessButtonKey = @"Less wrapLive stories";
static NSString *const WLMoreButtonKey = @"More wrapLive stories";
static CGFloat WLIndent = 31.0f;
static CGFloat WLMaxImageViewAspectRatio = 50.0f;
static CGFloat WLMaxRow = 6;
static CGFloat WLMinRow = 3;

@interface WLTodayViewController () <NCWidgetProviding>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *moreButton;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (strong, nonatomic) NSOrderedSet *contributions;
@property (assign, nonatomic) BOOL isShowMore;

@end

@implementation WLTodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self fetchContributions];
}

- (NCUpdateResult)fetchContributions {
    NSMutableOrderedSet *contributions = [NSMutableOrderedSet orderedSet];
    [contributions unionOrderedSet:[WLComment entries:^(NSFetchRequest *request) {
        request.predicate = [NSPredicate predicateWithFormat:@"contributor.current == NO AND createdAt > %@", [[NSDate now] beginOfDay]];
    }]];
    [contributions unionOrderedSet:[WLCandy entries:^(NSFetchRequest *request) {
        request.predicate = [NSPredicate predicateWithFormat:@"contributor.current == NO AND createdAt > %@", [[NSDate now] beginOfDay]];
    }]];
    [contributions sortByCreatedAt];
    NCUpdateResult updateResult = [self.contributions isEqualToOrderedSet:contributions] ? NCUpdateResultNoData : NCUpdateResultNewData;
    self.contributions = contributions;
    return updateResult;
}

- (void)setContributions:(NSOrderedSet *)contributions {
    _contributions = contributions;
    [self.tableView reloadData];
    [self setPreferredContentSize:CGSizeMake(0.0, self.tableView.contentSize.height)];
}

#pragma mark - NCWidgetProviding

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    [self updateExtensionWithResult:completionHandler];
}

- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets {
    return UIEdgeInsetsZero;
}

- (void)updateExtensionWithResult:(void(^)(NCUpdateResult))result {
    __weak __typeof(self)weakSelf = self;
    
    BOOL (^unauthorized) (void) = ^BOOL {
        if ([[WLAuthorization currentAuthorization] canAuthorize]) {
            return YES;
        }
        self.tableView.hidden = YES;
        self.signUpButton.hidden = NO;
        [self setPreferredContentSize:CGSizeMake(0.0, WLMaxImageViewAspectRatio)];
        return NO;
    };
    
    if (unauthorized()) {
        if (result) result(NCUpdateResultNoData);
    } else {
        if (![[WLAuthorization currentAuthorization] canAuthorize]) {
            self.tableView.hidden = YES;
            self.signUpButton.hidden = NO;
            [self setPreferredContentSize:CGSizeMake(0.0, WLMaxImageViewAspectRatio)];
            if (result) result(NCUpdateResultNoData);
            return;
        }
        
        [[WLRecentContributionsRequest request] send:^(NSOrderedSet *contributions) {
            [[WLEntryManager manager] save];
            weakSelf.moreButton.hidden = NO;
            weakSelf.tableView.hidden = NO;
            weakSelf.signUpButton.hidden = YES;
            if (result) result([weakSelf fetchContributions]);
        } failure:^(NSError *error) {
            if (unauthorized()) {
                if (result) result(NCUpdateResultNoData);
            } else {
                if (result) result(NCUpdateResultFailed);
            }
        }];
    }
}

- (IBAction)moreStories:(UIButton *)sender {
    self.isShowMore ^= 1;
    [sender setTitle:self.isShowMore ? WLLessButtonKey : WLMoreButtonKey forState:UIControlStateNormal];
    [self.tableView reloadData];
    [self setPreferredContentSize:CGSizeMake(0.0, self.tableView.contentSize.height)];
}

- (IBAction)singUpClick:(id)sender {
    [self.extensionContext openURL:[NSURL WLURLWithPath:@"/"] completionHandler:NULL];
}

#pragma mark - UITableViewDelegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return Smoothstep(0, self.isShowMore ? WLMaxRow : WLMinRow, [self.contributions count]);
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
//    return [self heightForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WLContribution *contribution = self.contributions[indexPath.row];
    if (contribution.identifier != nil) {
        [self.extensionContext openURL:[NSURL WLURLForRemoteEntryWithKey:WLCandyKey identifier:contribution.identifier] completionHandler:NULL];
    }
}

//- (CGFloat)heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    WLContribution* contribution = self.contributions[indexPath.row];
//    CGFloat widthLabel = self.tableView.frame.size.width - WLMaxImageViewAspectRatio - 5.0f;
//    CGFloat height = [contribution.event boundingRectWithSize:CGSizeMake(widthLabel, CGFLOAT_MAX)
//                                              options:NSStringDrawingUsesLineFragmentOrigin
//                                           attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15.0]}
//                                              context:nil].size.height;
//    height += WLIndent;
//    return MAX(height, WLMaxImageViewAspectRatio);
//}

@end
