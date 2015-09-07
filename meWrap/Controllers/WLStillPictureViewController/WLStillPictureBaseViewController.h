//
//  WLStillPictureBaseViewController.h
//  meWrap
//
//  Created by Ravenpod on 2/6/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"

@class WLStillPictureBaseViewController;
@class WLWrapView;
@protocol WLStillPictureBaseViewController;

@protocol WLStillPictureBaseViewControllerDelegate <NSObject>

@optional

- (void)stillPictureViewController:(id <WLStillPictureBaseViewController>)controller didSelectWrap:(WLWrap*)wrap;

@end

@protocol WLStillPictureBaseViewController <WLStillPictureBaseViewControllerDelegate>

@property (nonatomic) WLStillPictureMode mode;

@property (weak, nonatomic) WLWrap* wrap;

@property (weak, nonatomic) IBOutlet WLWrapView *wrapView;

@property (nonatomic, weak) id <WLStillPictureBaseViewControllerDelegate> delegate;

- (IBAction)selectWrap:(UIButton*)sender;

- (void)setupWrapView:(WLWrap *)wrap;

@end

@interface WLStillPictureBaseViewController : WLBaseViewController <WLStillPictureBaseViewController>

@end
