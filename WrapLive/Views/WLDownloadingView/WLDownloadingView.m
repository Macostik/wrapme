//
//  WLDownloadingView.m
//  WrapLive
//
//  Created by Yura Granchenko on 12/05/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLDownloadingView.h"
#import "NSObject+NibAdditions.h"
#import "WLProgressBar.h"

@interface WLDownloadingView ()

@property (weak, nonatomic) WLProgressBar *progressBar;
@property (weak, nonatomic) WLEntry *entry;

@end

@implementation WLDownloadingView

+ (instancetype)downloadingView {
    static WLDownloadingView *_downloadingView = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _downloadingView = [WLDownloadingView new];
    });
    
    return _downloadingView;
}

+ (instancetype)showDownloadingView:(UIView *)view forEntry:(WLEntry *)entry {
    return [[WLDownloadingView downloadingView] showDownloadingView:view forEntry:entry];
}

- (instancetype)showDownloadingView:(UIView *)view forEntry:(WLEntry *)entry {
    UIView *nibView = [WLDownloadingView loadFromNib];
    nibView.frame = view.frame;
    self.entry = entry;
    [view addSubview:nibView];
    [nibView setFullFlexible];
    nibView.alpha = 0.0f;
    [UIView animateWithDuration:0.5f delay:0.0f usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseIn animations:^{
        nibView.alpha = 1.0f;
    } completion:^(BOOL finished) {
        
    }];
    return self;
}

- (IBAction)hide {
    __weak typeof(self)weakSelf = self;
    [UIView animateWithDuration:0.25f delay:0.0f usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseIn animations:^{
        weakSelf.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [weakSelf removeFromSuperview];
    }];
}

@end
