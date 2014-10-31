//
//  WLCandyHeaderView.m
//  WrapLive
//
//  Created by Sergey Maximenko on 10/31/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCandyHeaderView.h"
#import "WLImageView.h"
#import "WLEntryManager.h"
#import "WLClearProgressBar.h"
#import "NSString+Additions.h"
#import "WLInternetConnectionBroadcaster.h"
#import "NSDate+Additions.h"

@interface WLCandyHeaderView ()

@property (weak, nonatomic) IBOutlet WLImageView *imageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet WLClearProgressBar *progressBar;

@end

@implementation WLCandyHeaderView

- (void)awakeFromNib {
    [super awakeFromNib];
    [[WLInternetConnectionBroadcaster broadcaster] addReceiver:self];
}

- (void)setCandy:(WLCandy *)candy {
    _candy = candy;
    __weak typeof(self)weakSelf = self;
    if (!self.spinner.isAnimating) [self.spinner startAnimating];
    [self.imageView setUrl:candy.picture.medium success:^(UIImage *image, BOOL cached) {
        if (weakSelf.spinner.isAnimating) [weakSelf.spinner stopAnimating];
    } failure:^(NSError *error) {
        if (weakSelf.spinner.isAnimating) [weakSelf.spinner stopAnimating];
    }];
    self.dateLabel.text = [NSString stringWithFormat:@"Posted %@", WLString(candy.createdAt.timeAgoString)];
    if (![WLInternetConnectionBroadcaster broadcaster].reachable) {
        self.progressBar.progress = .2f;
    } else {
        self.progressBar.operation = candy.uploading.operation;
    }
    self.progressBar.hidden = candy.uploaded;
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
