//
//  PGPhotoCell.m
//  PressGram-iOS
//
//  Created by Andrey Ivanov on 04.06.13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "WLAssetCell.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface WLAssetCell()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *acceptView;

@end

@implementation WLAssetCell

- (void)setup:(ALAsset *)asset {
    self.imageView.image = [UIImage imageWithCGImage:asset.aspectRatioThumbnail];
    if ([self.delegate respondsToSelector:@selector(assetCell:isSelectedAsset:)]) {
        BOOL selected = [self.delegate assetCell:self isSelectedAsset:asset];
        self.acceptView.hidden = !selected;
        self.imageView.alpha = selected ? 0.5f : 1.0f;
    }
}

- (IBAction)select:(id)sender {
	[self.delegate assetCell:self didSelectAsset:self.entry];
}

@end
