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
@property (weak, nonatomic) IBOutlet UILabel *videoIndicator;

@end

@implementation WLAssetCell

- (void)setup:(PHAsset *)asset {
    __weak __typeof(self)weakSelf = self;
    CGSize thumbnail = self.size;
    thumbnail.width *= [UIScreen mainScreen].scale;
    thumbnail.height *= [UIScreen mainScreen].scale;
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.synchronous = YES;
    options.networkAccessAllowed = NO;
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
    [[PHImageManager defaultManager] requestImageForAsset:asset
                                               targetSize:thumbnail
                                              contentMode:PHImageContentModeAspectFill
                                                  options:options
                                            resultHandler:^(UIImage *result, NSDictionary *info) {
                                                  weakSelf.imageView.image = result;
                                              }];
    self.videoIndicator.hidden = asset.mediaType != PHAssetMediaTypeVideo;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.acceptView.hidden = !selected;
    self.imageView.alpha = selected ? 0.5f : 1.0f;
}

@end
