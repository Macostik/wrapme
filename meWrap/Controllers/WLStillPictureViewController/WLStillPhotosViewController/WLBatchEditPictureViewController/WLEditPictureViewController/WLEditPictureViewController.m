//
//  WLEditPictureViewController.m
//  meWrap
//
//  Created by Ravenpod on 6/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEditPictureViewController.h"

@import AVKit;
@import AVFoundation;

@interface WLEditPictureViewController ()

@property (weak, nonatomic) IBOutlet ImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *deletionView;

@end

@implementation WLEditPictureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.imageView setUrl:self.picture.large];
    [self updateDeletionState];
}

- (BOOL)shouldUsePreferredViewFrame {
    return NO;
}

- (void)updateDeletionState {
    self.deletionView.hidden = !self.picture.deleted;
}

@end
