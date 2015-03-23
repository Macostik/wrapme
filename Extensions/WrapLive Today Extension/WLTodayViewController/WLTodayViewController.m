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

static NSString *const WLExtensionCellIdentifier = @"WLExtensionCellIdentifier";
static NSString *const WLCacheEntries = @"WLCacheEntries";
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
@property (strong, nonatomic) NSOrderedSet *entries;
@property (assign, nonatomic) BOOL isShowMore;

@end

@implementation WLTodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.entries = [NSOrderedSet unarchive:[[NSUserDefaults standardUserDefaults] objectForKey:WLCacheEntries]];
}

- (void)setEntries:(NSOrderedSet *)entries {
    __block NSMutableOrderedSet *entriesSet = [NSMutableOrderedSet orderedSet];
    [entries enumerateObjectsUsingBlock:^(WLExtensionEvent *post, NSUInteger idx, BOOL *stop) {
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
//    __weak __typeof(self)weakSelf = self;
//    if ([WLExtensionManager instance] == nil) {
//        [self.tableView removeFromSuperview];
//        self.signUpButton.hidden = NO;
//        [self setPreferredContentSize:CGSizeMake(0.0, WLMaxImageViewAspectRatio)];
//        if (result) {
//            result(NCUpdateResultNoData);
//        }
//        return;
//    }
//    
//    [WLExtensionEvent posts:^(NSArray *array) {
//        NSOrderedSet *entries = [NSOrderedSet orderedSetWithArray:array];
//        self.moreButton.hidden = NO;
//        if ([weakSelf isTheSameEntries:entries]) {
//            if (result) result(NCUpdateResultNoData);
//        } else {
//            weakSelf.entries = entries;
//            [[NSUserDefaults standardUserDefaults] setObject:[weakSelf.entries archive] forKey:WLCacheEntries];
//            [[NSUserDefaults standardUserDefaults] synchronize];
//            if (result) result(NCUpdateResultNewData);
//        }
//    } failure:^(NSError *error) {
//        if (![WLExtensionManager instance].authorized) {
//            [weakSelf.tableView removeFromSuperview];
//            weakSelf.signUpButton.hidden = NO;
//            [self setPreferredContentSize:CGSizeMake(0.0, WLMaxImageViewAspectRatio)];
//        }
//        if (result) result(NCUpdateResultFailed);
//    }];
}

- (IBAction)moreStories:(UIButton *)sender {
    self.isShowMore ^= 1;
    [sender setTitle:self.isShowMore? WLLessButtonKey : WLMoreButtonKey forState:UIControlStateNormal];
    [self.tableView reloadData];
    [self setPreferredContentSize:CGSizeMake(0.0, self.tableView.contentSize.height)];
}

- (IBAction)singUpClick:(id)sender {
    [self.extensionContext openURL:[NSURL WLURLWithPath:@"/"] completionHandler:NULL];
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
    WLExtensionEvent *selectedPost = self.entries[indexPath.row];
    if (selectedPost.identifier != nil) {
        [self.extensionContext openURL:[NSURL WLURLForRemoteEntryWithKey:WLCandyKey identifier:selectedPost.identifier] completionHandler:NULL];
    }
}

- (CGFloat)heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    WLExtensionEvent* post = self.entries[indexPath.row];
    CGFloat widthLabel = self.tableView.frame.size.width - WLMaxImageViewAspectRatio - 5.0f;
    CGFloat height = [post.event boundingRectWithSize:CGSizeMake(widthLabel, CGFLOAT_MAX)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15.0]}
                                              context:nil].size.height;
    height += WLIndent;
    return MAX(height, WLMaxImageViewAspectRatio);
}

- (BOOL)isTheSameEntries:(NSOrderedSet *)entries {
    if (entries.count == self.entries.count) {
        NSOrderedSet *lastTouches = [self.entries valueForKey:@"lastTouch"];
        for (WLExtensionEvent *post in entries) {
            if (![lastTouches containsObject:post.lastTouch] ) {
                return NO;
            }
        }
        return YES;
    }
    return NO;
}

@end
