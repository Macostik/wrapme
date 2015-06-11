//
//  PGPhotoLibraryCell.h
//  PressGram-iOS
//
//  Created by Ivanov Andrey on 04.06.13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "WLEntryCell.h"

@class WLAssetsGroupCell;
@class ALAssetsGroup;

@protocol WLAssetsGroupCellDelegate <NSObject>

- (void)assetsGroupCell:(WLAssetsGroupCell*)cell didSelectGroup:(ALAssetsGroup*)group;

@end

@interface WLAssetsGroupCell : WLEntryCell

@property (nonatomic, weak) IBOutlet id <WLAssetsGroupCellDelegate> delegate;

@end
