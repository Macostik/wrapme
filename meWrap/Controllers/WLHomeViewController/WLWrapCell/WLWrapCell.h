//
//  WLWrapCell.h
//  meWrap
//
//  Created by Ravenpod on 20.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "StreamReusableView.h"

@class WLWrapCell, WLBasicDataSource;

@protocol WLWrapCellDelegate <NSObject>

- (void)wrapCellDidBeginPanning:(WLWrapCell *)wrapCell;
- (void)wrapCellDidEndPanning:(WLWrapCell *)wrapCell performedAction:(BOOL)performedAction;
- (void)wrapCell:(WLWrapCell *)wrapCell presentChatViewControllerForWrap:(WLWrap *)wrap;
- (void)wrapCell:(WLWrapCell *)wrapCell presentCameraViewControllerForWrap:(WLWrap *)wrap;

@end

@interface WLWrapCell : StreamReusableView

@property (strong, nonatomic) IBOutlet id <WLWrapCellDelegate> delegate;

@end
