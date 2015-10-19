//
//  WLEditPictureCell.m
//  meWrap
//
//  Created by Ravenpod on 6/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEditPictureCell.h"
#import "WLEditPicture.h"

@interface WLEditPictureCell ()

@property (weak, nonatomic) IBOutlet WLImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIView *selectionView;
@property (weak, nonatomic) IBOutlet UIView *deletionView;
@property (weak, nonatomic) IBOutlet UILabel *videoIndicator;

@end

@implementation WLEditPictureCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.imageView.layer.borderColor = [UIColor whiteColor].CGColor;
}

- (void)setup:(WLEditPicture*)picture {
    self.imageView.url = picture.small;
    NSMutableString *status = [NSMutableString string];
    if (picture.comment.nonempty) [status appendString:@"4"];
    if (picture.edited) [status appendString:@"R"];
    if (status.nonempty) {
        self.statusLabel.attributedText = [[NSAttributedString alloc] initWithString:status attributes:@{NSForegroundColorAttributeName:self.statusLabel.textColor, NSFontAttributeName:self.statusLabel.font,NSKernAttributeName:@3}];
    } else {
        self.statusLabel.attributedText = nil;
    }
    self.selectionView.hidden = !picture.selected;
    self.deletionView.hidden = !picture.deleted;
    self.videoIndicator.hidden = picture.type != WLCandyTypeVideo;
}

@end
