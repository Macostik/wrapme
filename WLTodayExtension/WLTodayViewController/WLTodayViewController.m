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
static CGFloat  WLAuthorizedError = 401;
static CGFloat WLNoError = 0;
static CGFloat WLIndent = 31.0f;
static CGFloat WLMaxImageViewAspectRatio = 50.0f;
static CGFloat WLMaxRow = 6;
static CGFloat WLMinRow = 3;

@interface WLTodayViewController () <NCWidgetProviding>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *moreButton;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (strong, nonatomic) NSOrderedSet *entries;
@property (strong, nonatomic) NSUserDefaults *userDefaults;
@property (assign, nonatomic) int errorCode;
@property (assign, nonatomic) BOOL isShowMore;

@end

@implementation WLTodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.userDefaults = [NSUserDefaults standardUserDefaults];
    NSData *metaData = [self.userDefaults objectForKey:WLCacheEntries];
    self.entries = [NSOrderedSet unarchive:metaData];
}

- (void)setEntries:(NSOrderedSet *)entries {
    __block NSMutableOrderedSet *entriesSet = [NSMutableOrderedSet orderedSet];
    [entries enumerateObjectsUsingBlock:^(WLPost *post, NSUInteger idx, BOOL *stop) {
        if ([post.lastTouch isSameDay:[NSDate date]]) {
            [entriesSet addObject:post];
        }
    }];
    _entries = entriesSet;
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
    if ([WLExtensionManager instance] == nil) {
        [self.tableView removeFromSuperview];
        self.signUpButton.hidden = NO;
        [self setPreferredContentSize:CGSizeMake(0.0, WLMaxImageViewAspectRatio)];
        if (result) {
            result(NCUpdateResultNoData);
        }
        return;
    }
    [WLPost globalTimelinePostsWithBlock:^(NSArray *posts, NSError *error) {
        if (error && !posts.count) {
            NSHTTPURLResponse* response = [error.userInfo objectForKey:AFNetworkingOperationFailingURLResponseErrorKey];
            if (response && response.statusCode == WLAuthorizedError)
                [WLExtensionManager signInHandlerBlock:^(NSURLSessionDataTask *task, id responseObject) {
                    int errorCode = [[responseObject valueForKey:@"return_code"] intValue];
                    if (errorCode == WLNoError) {
                        [weakSelf updateExtensionWithResult:result];
                    } else {
                        [weakSelf.tableView removeFromSuperview];
                        weakSelf.signUpButton.hidden = NO;
                        [self setPreferredContentSize:CGSizeMake(0.0, WLMaxImageViewAspectRatio)];
                        weakSelf.errorCode = errorCode;
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
            self.moreButton.hidden = NO;
            if ([weakSelf isTheSameEntries:entries]) {
                if (result) {
                    result(NCUpdateResultNoData);
                }
            } else {
                weakSelf.entries = entries;
                [weakSelf.userDefaults setObject:[weakSelf.entries archive] forKey:WLCacheEntries];
                [weakSelf.userDefaults synchronize];
                weakSelf.errorCode = WLNoError;
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

- (IBAction)singUpClick:(id)sender {
    NSString *path = [[NSString stringWithFormat:@"/"]
                      stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    [self openUrlWithPath:path];
    self.errorCode = WLNoError;
}

#pragma mark - UITableViewDelegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self.entries count] >= WLMaxRow) {
        return self.isShowMore ? WLMaxRow : WLMinRow;
    } else if ([self.entries count] > WLMinRow) {
        return self.isShowMore ? [self.entries count] : WLMinRow;
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
        [self openUrlWithPath:path];
    }
}

- (void)openUrlWithPath:(NSString *)path {
    NSURL *url = [[NSURL alloc] initWithScheme:WLExtensionScheme host:nil path:path];
    [self.extensionContext openURL:url completionHandler:NULL];
}

- (CGFloat)heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    WLPost* post = self.entries[indexPath.row];
    CGFloat widthLabel = self.tableView.frame.size.width - WLMaxImageViewAspectRatio - 5.0f;
    CGFloat height = [post.event boundingRectWithSize:CGSizeMake(widthLabel, CGFLOAT_MAX)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15.0]}
                                              context:nil].size.height;
    height += WLIndent;
    return MAX(height, WLMaxImageViewAspectRatio);
}

- (BOOL)isTheSameEntries:(NSOrderedSet *)entries {
    BOOL flag = NO;
    if (entries.count == self.entries.count) {
        NSOrderedSet *lastTouches = [self.entries valueForKey:@"lastTouch"];
        for (WLPost *post in entries) {
            if ([lastTouches containsObject:post.lastTouch] ) {
                flag = YES;
            } else {
                return flag = NO;
            }
        }
        return flag;
    }
    return NO;
}

@end
