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
@property (strong, nonatomic) NSOrderedSet* comments;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@end

@implementation WLDetailedCandyCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.refresher = [WLRefresher refresher:self.tableView target:self action:@selector(refresh) style:WLRefresherStyleOrange];
//    [self.tableView setFullFlexible];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.contentView setFullFlexible];
    [[WLInternetConnectionBroadcaster broadcaster] addReceiver:self];
}

- (void)refresh {
    WLCandy* candy = self.item;
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

- (void)setupItemData:(WLCandy*)image {
    if (self.refresher.refreshing) {
        [self.refresher setRefreshing:NO animated:YES];
    }
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
    self.nameLabel.text = [NSString stringWithFormat:@"By %@", WLString(image.contributor.name)];
    self.progressBar.hidden = image.uploaded;
	[self reloadComments];
    if (!NSNumberEqual(image.unread, @NO)) image.unread = @NO;
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
                                                              options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont lightFontOfSize:15]} context:nil].size.height);
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
