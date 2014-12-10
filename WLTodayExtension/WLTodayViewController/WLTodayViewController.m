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
static NSString *const WLCacheEntries = @"WLCacheEntries";
static NSString *const WLLessButtonKey = @"Less wrapLive stories";
static NSString *const WLMoreButtonKey = @"More wrapLive stories";

@interface WLTodayViewController () <NCWidgetProviding>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *moreButton;
@property (strong, nonatomic) NSOrderedSet *entries;
@property (strong, nonatomic) NSUserDefaults *userDefaults;
@property (assign, nonatomic) BOOL isShowMore;

@end

@implementation WLTodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.userDefaults = [NSUserDefaults standardUserDefaults];
    NSData *metaData = [self.userDefaults objectForKey:WLCacheEntries];
    self.entries = [NSOrderedSet unarchive:metaData];
    if ([self.entries count]) {
        [self.tableView reloadData];
    }
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
    [WLPost globalTimelinePostsWithBlock:^(NSArray *posts, NSError *error) {
        if (error && !posts.count) {
            NSHTTPURLResponse* response = [error.userInfo objectForKey:AFNetworkingOperationFailingURLResponseErrorKey];
            if (response && response.statusCode == 401)
            [WLExtensionManager signInHandlerBlock:^(NSURLSessionDataTask *task, id responseObject) {
                if ([[responseObject valueForKey:@"return_code"] intValue] == 0) {
                    [weakSelf updateExtensionWithResult:result];
                } else {
                    weakSelf.moreButton.userInteractionEnabled = NO;
                    [weakSelf.moreButton setTitle:[responseObject valueForKey:@"message"] forState:UIControlStateNormal];
                    [weakSelf.moreButton setImage:[UIImage imageNamed:@"ic_alert_orange"] forState:UIControlStateNormal];
                    if (result) {
                        result(NCUpdateResultFailed);
                    }
                }
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                if (result) {
                    result(NCUpdateResultFailed);
                }
            }];
        } else {
            NSOrderedSet *entries = [NSOrderedSet orderedSetWithArray:posts];
            if ([weakSelf isTheSameEntries:entries]) {
                if (result) {
                    result(NCUpdateResultNoData);
                }
            } else {
                weakSelf.entries = entries;
                [weakSelf.userDefaults setObject:[weakSelf.entries archive] forKey:WLCacheEntries];
                [weakSelf.userDefaults synchronize];
                if ([weakSelf.entries count]) {
                    [weakSelf.tableView reloadData];
                }
                [weakSelf setPreferredContentSize:CGSizeMake(0.0, weakSelf.tableView.contentSize.height)];
                if (result) {
                     result(NCUpdateResultNewData);
                }
               
            }
        }
    }];
    
}

- (IBAction)moreStories:(UIButton *)sender {
    self.isShowMore ^= 1;
    [sender setTitle:self.isShowMore? WLLessButtonKey : WLMoreButtonKey forState:UIControlStateNormal];
    [self.tableView reloadData];
    [self setPreferredContentSize:CGSizeMake(0.0, self.tableView.contentSize.height)];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WLPost *selectedPost = self.entries[indexPath.row];
    if (selectedPost.identifier != nil) {
        NSString *path = [[NSString stringWithFormat:@"/candy?uid=%@", selectedPost.identifier]
                            stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
        NSURL *url = [[NSURL alloc] initWithScheme:WLExtensionScheme host:nil path:path];
        [self.extensionContext openURL:url completionHandler:NULL];
    }
}

static CGFloat WLIndent = 32.0f;
static CGFloat WLMaxImageViewHeight = 50.0f;

- (CGFloat)heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    WLPost* post = self.entries[indexPath.row];
    CGFloat widthLabel = self.tableView.frame.size.width - WLMaxImageViewHeight - 10.0f;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CGFloat height = [post.event boundingRectWithSize:CGSizeMake(widthLabel, CGFLOAT_MAX)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15.0]}
                                              context:nil].size.height;
#pragma clang diagnostic pop
    height += WLIndent;
    return MAX(height, WLMaxImageViewHeight);
}

- (BOOL)isTheSameEntries:(NSOrderedSet *)entries {
    BOOL flag = NO;
    if (entries.count == self.entries.count) {
        NSOrderedSet *lastTouches = [self.entries valueForKey:@"lastTouch"];
        for (WLPost *post in entries) {
            if ([lastTouches containsObject:post.lastTouch] ) {
                flag = YES;
            }else {
               return flag = NO;
            }
        }
        return flag;
    }
    return NO;
}

@end
