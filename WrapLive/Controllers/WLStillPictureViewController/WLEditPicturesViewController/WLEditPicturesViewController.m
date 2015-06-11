//
//  WLEditPicturesViewController.m
//  wrapLive
//
//  Created by Sergey Maximenko on 6/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEditPicturesViewController.h"
#import "WLWrapView.h"

@interface WLEditPicturesViewController ()

@end

@implementation WLEditPicturesViewController

@synthesize wrap = _wrap;

@synthesize delegate = _delegate;

@synthesize wrapView = _wrapView;

@synthesize mode = _mode;

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
        [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
    }
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
