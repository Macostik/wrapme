//
//  WLStillPictureBaseViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 2/6/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLStillPictureBaseViewController.h"
#import "WLWrap+Extended.h"
#import "WLWrapView.h"

@interface WLStillPictureBaseViewController ()

@end

@implementation WLStillPictureBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupWrapView:self.wrap];
}

- (void)setWrap:(WLWrap *)wrap {
    _wrap = wrap;
    if (self.isViewLoaded) {
        [self setupWrapView:wrap];
    }
}

- (void)setupWrapView:(WLWrap *)wrap {
    if (self.wrapView) {
        self.wrapView.entry = wrap;
        self.wrapView.hidden = wrap == nil;
    }
}

- (void)stillPictureViewController:(WLStillPictureBaseViewController *)controller didSelectWrap:(WLWrap *)wrap {
    [self selectWrap:nil];
}

- (IBAction)selectWrap:(UIButton *)sender {
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(stillPictureViewController:didSelectWrap:)]) {
            [self.delegate stillPictureViewController:self didSelectWrap:self.wrap];
        }
    } else if (self.presentingViewController) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
