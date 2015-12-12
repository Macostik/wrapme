//
//  WLEditPicturesViewController.h
//  meWrap
//
//  Created by Ravenpod on 6/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLStillPictureBaseViewController.h"
#import "WLSwipeViewController.h"

@class WLBatchEditPictureViewController;

@protocol WLBatchEditPictureViewControllerDelegate <WLStillPictureBaseViewControllerDelegate>

- (void)batchEditPictureViewController:(WLBatchEditPictureViewController*)controller didFinishWithAssets:(NSArray*)assets;

@end

@interface WLBatchEditPictureViewController : WLSwipeViewController <WLStillPictureBaseViewController>

@property (nonatomic, weak) id <WLBatchEditPictureViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet WrapView *wrapView;

@property (strong, nonatomic) NSArray* assets;

@end
