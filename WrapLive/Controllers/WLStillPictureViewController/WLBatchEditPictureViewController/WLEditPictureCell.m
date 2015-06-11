//
//  WLEditPictureCell.m
//  wrapLive
//
//  Created by Sergey Maximenko on 6/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEditPictureCell.h"
#import "WLPicture.h"
#import "WLImageView.h"

@interface WLEditPictureCell ()

@property (weak, nonatomic) IBOutlet WLImageView *imageView;

@end

@implementation WLEditPictureCell

- (void)setup:(WLPicture*)picture {
    self.imageView.url = picture.small;
}

@end
