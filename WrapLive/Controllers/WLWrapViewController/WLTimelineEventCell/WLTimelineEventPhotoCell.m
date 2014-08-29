//
//  WLTimelineEventPhotoCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/29/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTimelineEventPhotoCell.h"
#import "WLImageView.h"
#import "WLCandy.h"

@interface WLTimelineEventPhotoCell ()

@property (weak, nonatomic) IBOutlet WLImageView *imageView;

@end

@implementation WLTimelineEventPhotoCell

- (void)setup:(WLCandy*)image {
    self.imageView.animatingPicture = image.picture;
    self.imageView.url = image.picture.medium;
}

@end
