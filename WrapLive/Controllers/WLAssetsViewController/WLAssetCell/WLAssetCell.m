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

@end

@implementation WLAssetCell

- (void)setupItemData:(ALAsset *)asset {
    self.imageView.image = [UIImage imageWithCGImage:asset.thumbnail];
}

- (IBAction)select:(id)sender {
	[self.delegate assetCell:self didSelectAsset:self.item];
}

@end
