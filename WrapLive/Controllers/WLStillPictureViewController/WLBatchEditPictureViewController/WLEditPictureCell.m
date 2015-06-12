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
@property (weak, nonatomic) IBOutlet UIView *selectionView;
@property (weak, nonatomic) IBOutlet UIView *deletionView;

@end

@implementation WLEditPictureCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.imageView.layer.borderColor = [UIColor whiteColor].CGColor;
}

- (void)setup:(WLEditPicture*)picture {
    self.imageView.url = picture.small;
    self.statusLabel.text = [NSString stringWithFormat:@"%@%@",picture.comment.nonempty ? @"5":@"",picture.edited ? @"R":@""];
    self.selectionView.hidden = !picture.selected;
    self.deletionView.hidden = !picture.deleted;
}

@end
