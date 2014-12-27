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
#import "WLProgressBar+WLContribution.h"
#import "NSString+Additions.h"
#import "WLNetwork.h"
#import "NSDate+Additions.h"

@interface WLCandyHeaderView ()

@property (weak, nonatomic) IBOutlet WLImageView *imageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet WLProgressBar *progressBar;

@end

@implementation WLCandyHeaderView

- (void)awakeFromNib {
    [super awakeFromNib];
    [[WLNetwork network] addReceiver:self];
    [self.imageView setContentMode:UIViewContentModeCenter forState:WLImageViewStateFailed];
    [self.imageView setContentMode:UIViewContentModeCenter forState:WLImageViewStateEmpty];
    [self.imageView setImageName:@"ic_photo_placeholder" forState:WLImageViewStateFailed];
    [self.imageView setImageName:@"ic_photo_placeholder" forState:WLImageViewStateEmpty];
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
    self.dateLabel.text = [NSString stringWithFormat:WLLS(@"Posted %@"), WLString(candy.createdAt.timeAgoString)];
    self.progressBar.contribution = candy;
}

@end
