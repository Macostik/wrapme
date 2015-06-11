//
//  WLEditPictureViewController.m
//  wrapLive
//
//  Created by Sergey Maximenko on 6/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEditPictureViewController.h"
#import "WLImageView.h"

@interface WLEditPictureViewController ()

@property (weak, nonatomic) IBOutlet WLImageView *imageView;

@end

@implementation WLEditPictureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.imageView.url = self.picture.large;
}

@end
