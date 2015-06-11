//
//  WLEditPicturesViewController.h
//  wrapLive
//
//  Created by Sergey Maximenko on 6/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLStillPictureBaseViewController.h"
#import "WLSwipeViewController.h"

@class WLBatchEditPictureViewController;

@protocol WLBatchEditPictureViewControllerDelegate <WLStillPictureBaseViewControllerDelegate>

- (void)batchEditPictureViewController:(WLBatchEditPictureViewController*)controller didFinishWithPictures:(NSArray*)pictures;

@end

@interface WLBatchEditPictureViewController : WLSwipeViewController <WLStillPictureBaseViewController>

@property (nonatomic, weak) id <WLBatchEditPictureViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet WLWrapView *wrapView;

@property (strong, nonatomic) NSArray* pictures;

@end
