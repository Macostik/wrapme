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

@interface WLDetailedCandyCell () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet WLImageView *imageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) WLRefresher *refresher;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (strong, nonatomic) NSOrderedSet* comments;

@end

@implementation WLDetailedCandyCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.refresher = [WLRefresher refresherWithScrollView:self.tableView target:self action:@selector(refresh) colorScheme:WLRefresherColorSchemeOrange];
    [self setFullFlexible];
    [[WLInternetConnectionBroadcaster broadcaster] addReceiver:self];
}

- (void)refresh {
    WLCandy* candy = self.item;
	if (candy.uploaded) {
		__weak typeof(self)weakSelf = self;
        [candy fetch:^(id object) {
			[weakSelf.refresher endRefreshing];
        } failure:^(NSError *error) {
            [error showIgnoringNetworkError];
			[weakSelf.refresher endRefreshing];
        }];
	} else {
        [self.refresher endRefreshing];
    }
}

- (void)setupItemData:(WLCandy*)image {
	__weak typeof(self)weakSelf = self;
    if (![WLInternetConnectionBroadcaster broadcaster].reachable) {
        self.progressBar.progress = .2f;
    } else {
        self.progressBar.operation = image.uploading.operation;
    }
	if (!self.spinner.isAnimating) {
		[self.spinner startAnimating];
	}
	[self.imageView setUrl:image.picture.medium success:^(UIImage *image, BOOL cached) {
        if (weakSelf.spinner.isAnimating) {
			[weakSelf.spinner stopAnimating];
		}
    } failure:^(NSError *error) {
        if (weakSelf.spinner.isAnimating) {
			[weakSelf.spinner stopAnimating];
		}
    }];
	self.dateLabel.text = [NSString stringWithFormat:@"Posted %@", WLString(image.createdAt.timeAgoString)];
    self.progressBar.hidden = image.uploaded;
	[self reloadComments];
    image.unread = @NO;
}

- (void)reloadComments {
    WLCandy* candy = self.item;
    self.comments = candy.comments;
    [self.tableView reloadData];
}

#pragma mark - <UITableViewDataSource, UITableViewDelegate>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLComment* comment = [self.comments objectAtIndex:indexPath.row];
	WLCommentCell* cell = [tableView dequeueReusableCellWithIdentifier:WLCommentCellIdentifier forIndexPath:indexPath];
	cell.item = comment;
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLComment* comment = [self.comments objectAtIndex:indexPath.row];
	CGFloat commentHeight  = ceilf([comment.text boundingRectWithSize:CGSizeMake(WLCommentLabelLenth, CGFLOAT_MAX)
                                                              options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[WLCommentCell commentFont]} context:nil].size.height);
	CGFloat cellHeight = (commentHeight + WLAuthorLabelHeight);
	return MAX(WLMinimumCellHeight, cellHeight + 10);
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
