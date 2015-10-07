//
//  WLEditPictureViewController.m
//  meWrap
//
//  Created by Ravenpod on 6/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEditPictureViewController.h"
#import "WLEditPicture.h"
#import "WLKeyboard.h"

@import AVKit;
@import AVFoundation;

@interface WLEditPictureViewController ()

@property (weak, nonatomic) IBOutlet WLImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *deletionView;
@property (weak, nonatomic) IBOutlet UIButton *playVideoButton;
@property (weak, nonatomic) IBOutlet UIToolbar *playVideoToolbar;

@end

@implementation WLEditPictureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.imageView setUrl:self.picture.large];
    self.playVideoToolbar.hidden = self.playVideoButton.hidden = self.picture.type != WLCandyTypeVideo;
    [self updateDeletionState];
}

- (void)updateDeletionState {
    self.deletionView.hidden = !self.picture.deleted;
}

- (IBAction)playVideo:(id)sender {
    if ([WLKeyboard keyboard].isShow) {
        [self.view.window endEditing:YES];
    } else {
        AVPlayerViewController *controller = [[AVPlayerViewController alloc] init];
        controller.player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:self.picture.original]];
        [self presentViewController:controller animated:NO completion:nil];
        [controller.player play];
    }
}

@end
