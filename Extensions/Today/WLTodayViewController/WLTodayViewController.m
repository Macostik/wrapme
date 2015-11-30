//
//  WLTodayViewController.m
//  WLTodayExtension
//
//  Created by Yura Granchenko on 11/27/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import "GeometryHelper.h"

@interface WLTodayContributionCell : UITableViewCell

@property (weak, nonatomic) Contribution *contribution;

@property (weak, nonatomic) IBOutlet UIImageView *pictureView;

@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@property (weak, nonatomic) IBOutlet UILabel *wrapNameLabel;

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@end

@interface WLTodayCommentCell : WLTodayContributionCell

@end

@interface WLTodayCandyCell : WLTodayContributionCell

@end

@implementation WLTodayContributionCell

- (void)setContribution:(Contribution *)contribution {
    _contribution = contribution;
    self.timeLabel.text = [contribution.createdAt timeAgoStringAtAMPM];
    __weak typeof(self)weakSelf = self;
    NSString *url = contribution.picture.small;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:url]]];
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.pictureView.image = image;
        });
    });
}

@end

@implementation WLTodayCommentCell

- (void)setContribution:(Comment *)comment {
    [super setContribution:comment];
    self.wrapNameLabel.text = comment.candy.wrap.name;
    self.descriptionLabel.text = [NSString stringWithFormat:@"%@ commented \"%@\"", comment.contributor.name, comment.text];
}

@end

@implementation WLTodayCandyCell

- (void)setContribution:(Candy *)candy {
    [super setContribution:candy];
    self.wrapNameLabel.text = candy.wrap.name;
    self.descriptionLabel.text = [NSString stringWithFormat:@"%@ posted a new photo", candy.contributor.name];
}

@end

static NSString *const WLTodayCandyCellIdentifier = @"WLTodayCandyCell";
static NSString *const WLTodayCommentCellIdentifier = @"WLTodayCommentCell";
static CGFloat WLMaxRow = 6;
static CGFloat WLMinRow = 3;

typedef NS_ENUM(NSUInteger, WLTodayViewState) {
    WLTodayViewStateUnauthorized,
    WLTodayViewStateShowMore,
    WLTodayViewStateShowLess,
    WLTodayViewStateNoFooter
};

@interface WLTodayViewController () <NCWidgetProviding>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *moreButton;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (strong, nonatomic) NSArray *contributions;

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

- (void)viewWillAppear:(BOOL)animated {
    [self fetchContributions];
}

- (void)setState:(WLTodayViewState)state {
    _state = state;
    
    switch (state) {
        case WLTodayViewStateUnauthorized:
            if (!self.tableView.tableFooterView) self.tableView.tableFooterView = self.tableFooterView;
            self.signUpButton.hidden = NO;
            self.moreButton.hidden = YES;
            break;
        case WLTodayViewStateShowMore:
            if (!self.tableView.tableFooterView) self.tableView.tableFooterView = self.tableFooterView;
            [self.moreButton setTitle:@"more_today_stories".ls forState:UIControlStateNormal];
            self.signUpButton.hidden = YES;
            self.moreButton.hidden = NO;
            break;
        case WLTodayViewStateShowLess:
            if (!self.tableView.tableFooterView) self.tableView.tableFooterView = self.tableFooterView;
            [self.moreButton setTitle:@"less_today_stories".ls forState:UIControlStateNormal];
            self.signUpButton.hidden = YES;
            self.moreButton.hidden = NO;
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
    NSArray *contributions = [Contribution recentContributions:6];
    NCUpdateResult updateResult = [self.contributions isEqualToArray:contributions] ? NCUpdateResultNoData : NCUpdateResultNewData;
    self.contributions = contributions;
    return updateResult;
}

- (void)setContributions:(NSArray *)contributions {
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
    if ([User currentUser] == nil) {
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
    ExtensionRequest *request = [[ExtensionRequest alloc] initWithAction:@"authorize" parameters:nil];
    NSURL *url = [request serializedURL];
    if (url) {
        [self.extensionContext openURL:url completionHandler:NULL];
    }
}

#pragma mark - UITableViewDelegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return Smoothstep(0, self.state == WLTodayViewStateShowLess ? WLMaxRow : WLMinRow, [self.contributions count]);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Contribution *contribution = self.contributions[indexPath.row];
    if ([contribution isKindOfClass:[Comment class]]) {
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
    Contribution *contribution = self.contributions[indexPath.row];
    if (contribution.identifier == nil) {
        return;
    }
    ExtensionRequest *request = [[ExtensionRequest alloc] initWithAction:@"presentEntry" parameters:contribution.serializeReference];
    NSURL *url = [request serializedURL];
    if (url) {
        [self.extensionContext openURL:url completionHandler:NULL];
    }
}

@end
