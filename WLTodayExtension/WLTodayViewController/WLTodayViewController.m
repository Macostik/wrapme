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
                [weakSelf updateExtension];
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                NSLog(@"%@", error.description);
            }];
        } else {
            weakSelf.entries = [NSOrderedSet orderedSetWithArray:posts];
            if ([weakSelf.entries count]) {
                [weakSelf.tableView reloadData];
            }
            weakSelf.tableView.estimatedRowHeight = 50;
            weakSelf.tableView.rowHeight = UITableViewAutomaticDimension;
            [weakSelf setPreferredContentSize:CGSizeMake(0.0, self.tableView.contentSize.height)];
        }
        
    }];
    
}

- (IBAction)moreStories:(UIButton *)sender {
    self.isShowMore ^= 1;
    [sender setTitle:self.isShowMore? WLLessButtonKey : WLMoreButtonKey forState:UIControlStateNormal];
    [self.tableView reloadData];
    [self setPreferredContentSize:CGSizeMake(0.0, self.tableView.contentSize.height)];
    NSURL *url = [[NSURL alloc] initWithScheme:WLExtensionScheme host:nil path:@"/test"];
    [self.extensionContext openURL:url completionHandler:^(BOOL success) {
        
    }];
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
    WLExtensionCell *cell = [tableView dequeueReusableCellWithIdentifier:WLExtensionCellIdentifier];
    cell.attEntry = self.entries[indexPath.row];
    
    return cell;
}

@end
