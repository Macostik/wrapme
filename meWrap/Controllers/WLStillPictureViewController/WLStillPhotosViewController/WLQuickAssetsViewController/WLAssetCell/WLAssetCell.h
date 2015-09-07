//
//  PGPhotoCell.h
//  meWrap
//
//  Created by Andrey Ivanov on 04.06.13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "WLEntryCell.h"

@import Photos;

@class WLAssetCell;

@protocol WLAssetCellDelegate <NSObject>

- (void)assetCell:(WLAssetCell*)cell didSelectAsset:(PHAsset*)asset;

@optional

- (BOOL)assetCell:(WLAssetCell*)cell isSelectedAsset:(PHAsset*)asset;

- (BOOL)assetCellAllowsMultipleSelection:(WLAssetCell*)cell;

@end

@interface WLAssetCell : WLEntryCell

@property (nonatomic, weak) IBOutlet id <WLAssetCellDelegate> delegate;

@end
