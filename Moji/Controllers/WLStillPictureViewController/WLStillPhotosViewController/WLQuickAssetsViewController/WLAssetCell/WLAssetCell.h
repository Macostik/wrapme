//
//  PGPhotoCell.h
//  moji
//
//  Created by Andrey Ivanov on 04.06.13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "WLEntryCell.h"

@class ALAsset;
@class WLAssetCell;

@protocol WLAssetCellDelegate <NSObject>

- (void)assetCell:(WLAssetCell*)cell didSelectAsset:(ALAsset*)asset;

@optional

- (BOOL)assetCell:(WLAssetCell*)cell isSelectedAsset:(ALAsset*)asset;

@end

@interface WLAssetCell : WLEntryCell

@property (nonatomic, weak) IBOutlet id <WLAssetCellDelegate> delegate;

@end
