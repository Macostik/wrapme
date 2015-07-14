//
//  WLWrapCell.h
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEntryCell.h"

static NSUInteger WLHomeTopWrapCandiesLimit = 6;
static NSUInteger WLHomeTopWrapCandiesLimit_2 = 3;

@class WLWrapCell, WLBasicDataSource;

@protocol WLWrapCellDelegate <NSObject>

- (void)wrapCellDidBeginPanning:(WLWrapCell *)wrapCell;
- (void)wrapCellDidEndPanning:(WLWrapCell *)wrapCell performedAction:(BOOL)performedAction;
- (void)wrapCell:(WLWrapCell *)wrapCell presentChatViewControllerForWrap:(WLWrap *)wrap;
- (void)wrapCell:(WLWrapCell *)wrapCell presentCameraViewControllerForWrap:(WLWrap *)wrap;

@end

@interface WLWrapCell : WLEntryCell

@property (strong, nonatomic) IBOutlet id <WLWrapCellDelegate> delegate;
@property (strong, nonatomic, readonly) WLBasicDataSource* candiesDataSource;
@property (weak, nonatomic, readonly) UICollectionView *candiesView;

@end
