//
//  TodayViewController.m
//  WLTodayExtension
//
//  Created by Yura Granchenko on 11/27/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import "WLExtensionCell.h"
#import "WLEntryKeys.h"

static NSString *const WLUserDefaultsExtensionKey = @"group.com.ravenpod.wraplive";
static NSString *const WLExtensionWrapKey = @"WLExtansionWrapKey";
static CGFloat WLMinHeightView = 140.0f;
static CGFloat WLMaxHeightView = 400.0;

@interface TodayViewController () <NCWidgetProviding>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableOrderedSet *entries;

@end

@implementation TodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateExtension];
    [self setPreferredContentSize:CGSizeMake(0.0, WLMinHeightView)];
    self.tableView.estimatedRowHeight = 50;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self fullHeightTableView:NO];
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    [self updateExtension];
    completionHandler(NCUpdateResultNewData);
}

- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets {
    return UIEdgeInsetsZero;
}

- (void)updateExtension {
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:WLUserDefaultsExtensionKey];
    NSDictionary *attDictionary = [userDefaults objectForKey:WLExtensionWrapKey];
    self.entries = [attDictionary objectForKey:WLContentKey];
    [self.tableView reloadData];
}

- (void)fullHeightTableView:(BOOL)fullFlag {
    CGRect frame = self.view.bounds;
    frame.size.height = fullFlag ? WLMaxHeightView : WLMinHeightView;
    self.view.frame = frame;
    [self.view layoutIfNeeded];
}

- (IBAction)moreStories:(id)sender {
    [self setPreferredContentSize:CGSizeMake(0.0, WLMinHeightView)];
    [self fullHeightTableView:YES];
    [self.tableView reloadData];
    self.tableView.hidden = YES;
}

- (void)viewWillTransitionToSize:(CGSize)size
      withTransitionCoordinator:
(id<UIViewControllerTransitionCoordinator>)coordinator {
    __weak __typeof(self)weakSelf = self;
    [coordinator animateAlongsideTransition:
     ^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         weakSelf.tableView.hidden = NO;
     } completion:nil];
}

#pragma mark - UITableViewDelegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.entries count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"WLExtensionCell";
    WLExtensionCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    cell.attEntry = self.entries[indexPath.row];
    
    return cell;
}

@end
