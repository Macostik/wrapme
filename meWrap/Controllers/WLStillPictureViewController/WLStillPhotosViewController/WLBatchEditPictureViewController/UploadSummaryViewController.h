//
//  WLEditPicturesViewController.h
//  meWrap
//
//  Created by Ravenpod on 6/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLStillPictureBaseViewController.h"
#import "WLSwipeViewController.h"

@class UploadSummaryViewController, WrapView, MutableAsset;

@protocol UploadSummaryViewControllerDelegate <WLStillPictureBaseViewControllerDelegate>

- (void)uploadSummaryViewController:(UploadSummaryViewController*)controller didFinishWithAssets:(NSArray*)assets;
- (void)uploadSummaryViewController:(UploadSummaryViewController *)controller didDeselectAsset:(MutableAsset *)asset;

@end

@interface UploadSummaryViewController : WLSwipeViewController <WLStillPictureBaseViewController>

@property (nonatomic, weak) id <UploadSummaryViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet WrapView *wrapView;

@property (strong, nonatomic) NSArray* assets;

@end
