//
//  WLDetailedCandyCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/11/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLDetailedCandyCell.h"
#import "WLEntryManager.h"
#import "WLImageView.h"
#import "WLRefresher.h"
#import "WLAPIManager.h"
#import "WLInternetConnectionBroadcaster.h"
#import "NSString+Additions.h"
#import "NSDate+Additions.h"
#import "WLCommentCell.h"
#import "UIView+Shorthand.h"
#import "UIFont+CustomFonts.h"

@interface WLDetailedCandyCell () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet WLImageView *imageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) WLRefresher *refresher;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIView *topView;

@end

@implementation WLDetailedCandyCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.tableView.contentInset = UIEdgeInsetsMake(64, 0, 44, 0);
    self.refresher = [WLRefresher refresher:self.tableView target:self action:@selector(refresh) style:WLRefresherStyleOrange];
    [[WLInternetConnectionBroadcaster broadcaster] addReceiver:self];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UIView* headerView = self.tableView.tableHeaderView;
    if (headerView.height != self.width) {
        headerView.height = self.width;
        self.tableView.tableHeaderView = headerView;
    }
}

- (void)refresh {
    WLCandy* candy = self.entry;
	if (candy.uploaded) {
		__weak typeof(self)weakSelf = self;
        [candy fetch:^(id object) {
			[weakSelf.refresher setRefreshing:NO animated:YES];
        } failure:^(NSError *error) {
            [error showIgnoringNetworkError];
			[weakSelf.refresher setRefreshing:NO animated:YES];
        }];
	} else {
        [self.refresher setRefreshing:NO animated:YES];
    }
}

- (void)setEntry:(id)entry {
    if (self.entry != entry) {
        self.tableView.contentOffset = CGPointMake(0, -64);
    }
    [super setEntry:entry];
}

- (void)setup:(WLCandy*)candy {
    if (self.refresher.refreshing) {
        [self.refresher setRefreshing:NO animated:YES];
    }
	__weak typeof(self)weakSelf = self;
	if (!self.spinner.isAnimating) [self.spinner startAnimating];
	[self.imageView setUrl:candy.picture.medium success:^(UIImage *image, BOOL cached) {
        if (weakSelf.spinner.isAnimating) [weakSelf.spinner stopAnimating];
    } failure:^(NSError *error) {
        if (weakSelf.spinner.isAnimating) [weakSelf.spinner stopAnimating];
    }];
	self.dateLabel.text = [NSString stringWithFormat:@"Posted %@", WLString(candy.createdAt.timeAgoString)];
    self.nameLabel.text = [NSString stringWithFormat:@"By %@", WLString(candy.contributor.name)];
    if (![WLInternetConnectionBroadcaster broadcaster].reachable) {
        self.progressBar.progress = .2f;
    } else {
        self.progressBar.operation = candy.uploading.operation;
    }
    self.progressBar.hidden = candy.uploaded;
	[self.tableView reloadData];
    if (!NSNumberEqual(candy.unread, @NO)) candy.unread = @NO;
}

- (void)updateBottomInset:(CGFloat)bottomInset {
    UIEdgeInsets insets = self.tableView.contentInset;
    insets.bottom = bottomInset;
    self.tableView.contentInset = insets;
}

#pragma mark - <UITableViewDataSource, UITableViewDelegate>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    WLCandy* candy = self.entry;
	return candy.comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WLCandy* candy = self.entry;
	WLComment* comment = [candy.comments tryObjectAtIndex:indexPath.row];
	WLCommentCell* cell = [tableView dequeueReusableCellWithIdentifier:WLCommentCellIdentifier forIndexPath:indexPath];
    cell.item = comment.valid ? comment : nil;
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    WLCandy* candy = self.entry;
	WLComment* comment = [candy.comments tryObjectAtIndex:indexPath.row];
    if (comment.valid) {
        CGFloat commentHeight  = ceilf([comment.text boundingRectWithSize:CGSizeMake(WLCommentLabelLenth, CGFLOAT_MAX)
                                                                  options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont lightFontOfSize:15]} context:nil].size.height);
        CGFloat cellHeight = (commentHeight + WLAuthorLabelHeight);
        return MAX(WLMinimumCellHeight, cellHeight + 10);
    }
    return WLMinimumCellHeight;
}

#pragma mark - WLInternetConnectionBroadcaster

- (void)broadcaster:(WLInternetConnectionBroadcaster *)broadcaster internetConnectionReachable:(NSNumber *)reachable {
    if (![reachable boolValue]) {
        run_in_main_queue(^{
            self.progressBar.progress = .2f;
        });
    }
}

@end
