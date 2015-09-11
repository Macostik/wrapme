//
//  PGPhotoCell.m
//  meWrap
//
//  Created by Andrey Ivanov on 04.06.13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "WLAssetCell.h"
@import Photos;

@interface WLAssetCell()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *acceptView;

@property (nonatomic) PHImageRequestID imageRequestID;

@end

@implementation WLAssetCell

- (void)prepareForReuse {
    [super prepareForReuse];
    [[PHImageManager defaultManager] cancelImageRequest:self.imageRequestID];
}

- (void)setup:(PHAsset *)asset {
    __weak __typeof(self)weakSelf = self;
    CGSize thumbnail = self.size;
    thumbnail.width *= [UIScreen mainScreen].scale;
    thumbnail.height *= [UIScreen mainScreen].scale;
    self.imageRequestID = [[PHImageManager defaultManager] requestImageForAsset:asset
                                               targetSize:thumbnail
                                              contentMode:PHImageContentModeAspectFill
                                                  options:nil
                                            resultHandler:^(UIImage *result, NSDictionary *info) {
                                                  weakSelf.imageView.image = result;
                                              }];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.acceptView.hidden = !selected;
    self.imageView.alpha = selected ? 0.5f : 1.0f;
}

@end
