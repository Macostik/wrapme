//
//  PGPhotoCell.h
//  PressGram-iOS
//
//  Created by Andrey Ivanov on 04.06.13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "WLCollectionItemCell.h"

@class ALAsset;
@class WLAssetCell;

@protocol WLAssetCellDelegate <NSObject>

- (void)assetCell:(WLAssetCell*)cell didSelectAsset:(ALAsset*)asset;

@end

@interface WLAssetCell : WLCollectionItemCell

@property (nonatomic, weak) id <WLAssetCellDelegate> delegate;

@property (nonatomic) BOOL checked;

@end
