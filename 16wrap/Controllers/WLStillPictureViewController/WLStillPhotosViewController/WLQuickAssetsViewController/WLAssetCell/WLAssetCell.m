//
//  PGPhotoCell.m
//  moji
//
//  Created by Andrey Ivanov on 04.06.13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "WLAssetCell.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface WLAssetCell()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *acceptView;
@property (weak, nonatomic) IBOutlet UIButton *selectButton;

@end

@implementation WLAssetCell

- (void)setup:(PHAsset *)asset {
    __weak __typeof(self)weakSelf = self;
    CGSize thumbnail = CGSizeMake(100, 100);
    [[PHImageManager defaultManager] requestImageForAsset:asset
                                               targetSize:thumbnail
                                              contentMode:PHImageContentModeAspectFill
                                                  options:nil
                                            resultHandler:^(UIImage *result, NSDictionary *info) {
                                                  weakSelf.imageView.image = result;
                                              }];
    if ([self.delegate respondsToSelector:@selector(assetCell:isSelectedAsset:)]) {
        BOOL selected = [self.delegate assetCell:self isSelectedAsset:asset];
        self.acceptView.hidden = !selected;
        self.imageView.alpha = selected ? 0.5f : 1.0f;
    }
    
    if ([self.delegate respondsToSelector:@selector(assetCellAllowsMultipleSelection:)]) {
        self.selectButton.exclusiveTouch = ![self.delegate assetCellAllowsMultipleSelection:self];
    } else {
        self.selectButton.exclusiveTouch = YES;
    }
}

- (IBAction)select:(id)sender {
	[self.delegate assetCell:self didSelectAsset:self.entry];
}

@end
