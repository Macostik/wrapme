//
//  WLTodayViewController.m
//  WLTodayExtension
//
//  Created by Yura Granchenko on 11/27/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import "WLExtensionCell.h"
#import "WLEntryKeys.h"
#import "WLExtensionManager.h"

static NSString *const WLExtensionCellIdentifier = @"WLExtensionCellIdentifier";
static NSString *const WLExtensionScheme = @"WLExtensionScheme";
static NSString *const WLLessButtonKey = @"Less wrapLive stories";
static NSString *const WLMoreButtonKey = @"More wrapLive stories";

@interface WLTodayViewController () <NCWidgetProviding>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *moreButton;
@property (strong, nonatomic) NSOrderedSet *entries;
@property (assign, nonatomic) BOOL isShowMore;

@end

@implementation WLTodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    [self updateExtension];
    completionHandler(NCUpdateResultNewData);
}

- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets {
    return UIEdgeInsetsZero;
}

- (void)updateExtension {
    __weak __typeof(self)weakSelf = self;
    [WLPost globalTimelinePostsWithBlock:^(NSArray *posts, NSError *error) {
        if (error && !posts.count) {
            NSHTTPURLResponse* response = [error.userInfo objectForKey:AFNetworkingOperationFailingURLResponseErrorKey];
            if (response && response.statusCode == 401)
            [WLExtensionManager signInHandlerBlock:^(NSURLSessionDataTask *task, id responseObject) {
                if ([[responseObject valueForKey:@"return_code"] intValue] == 0) {
                    [weakSelf updateExtension];
                } else {
                    weakSelf.moreButton.userInteractionEnabled = NO;
                    [weakSelf.moreButton setTitle:[responseObject valueForKey:@"message"] forState:UIControlStateNormal];
                    [weakSelf.moreButton setImage:[UIImage imageNamed:@"ic_alert_orange"] forState:UIControlStateNormal];
                }
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                NSLog(@"%@", error.description);
            }];
        } else {
            weakSelf.entries = [NSOrderedSet orderedSetWithArray:posts];
            if ([weakSelf.entries count]) {
                [weakSelf.tableView reloadData];
            }
            [weakSelf setPreferredContentSize:CGSizeMake(0.0, weakSelf.tableView.contentSize.height)];
        }
    }];
    
}

- (IBAction)moreStories:(UIButton *)sender {
    self.isShowMore ^= 1;
    [sender setTitle:self.isShowMore? WLLessButtonKey : WLMoreButtonKey forState:UIControlStateNormal];
    [self.tableView reloadData];
    [self setPreferredContentSize:CGSizeMake(0.0, self.tableView.contentSize.height)];
//    NSURL *url = [[NSURL alloc] initWithScheme:WLExtensionScheme host:nil path:@"/test"];
//    [self.extensionContext openURL:url completionHandler:^(BOOL success) {
//        
//    }];
}

#pragma mark - UITableViewDelegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self.entries count] >= 6) {
        return self.isShowMore ? 6 : 3;
    } else if ([self.entries count] > 3) {
        return self.isShowMore ? [self.entries count] : 3;
    } else  {
        return [self.entries count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WLExtensionCell *cell = [tableView dequeueReusableCellWithIdentifier:WLExtensionCellIdentifier forIndexPath:indexPath];
    cell.post = self.entries[indexPath.row];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self heightForRowAtIndexPath:indexPath];
}

static CGFloat WLIndent = 32.0f;
static CGFloat WLEventLabelWidth = 252.0f;
static CGFloat WLMaxImageViewHeight = 50.0f;

- (CGFloat)heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    WLPost* post = self.entries[indexPath.row];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CGFloat height = [post.event sizeWithFont:[UIFont systemFontOfSize:15.0]
                            constrainedToSize:CGSizeMake(WLEventLabelWidth, CGFLOAT_MAX)
                                lineBreakMode:NSLineBreakByWordWrapping].height;
#pragma clang diagnostic pop
    height += WLIndent;
    return MAX(height, WLMaxImageViewHeight);
}


@end
