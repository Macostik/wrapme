//
//  WLEditPictureCell.m
//  wrapLive
//
//  Created by Sergey Maximenko on 6/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEditPictureCell.h"
#import "WLImageView.h"

@interface WLEditPictureCell ()

@property (weak, nonatomic) IBOutlet WLImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@end

@implementation WLEditPictureCell

- (void)setup:(WLEditPicture*)picture {
    self.imageView.url = picture.small;
    self.statusLabel.text = [NSString stringWithFormat:@"%@ %@",picture.comment.nonempty ? @"Y":@"",picture.edited ? @"R":@""];
}

@end
