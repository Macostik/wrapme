//
//  WLStillPictureBaseViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 2/6/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"

@class WLStillPictureBaseViewController;
@class WLWrapView;

@protocol WLStillPictureBaseViewControllerDelegate <NSObject>

@optional

- (void)stillPictureViewController:(WLStillPictureBaseViewController*)controller didSelectWrap:(WLWrap*)wrap;

@end

@interface WLStillPictureBaseViewController : WLBaseViewController <WLStillPictureBaseViewControllerDelegate>

@property (nonatomic) WLStillPictureMode mode;

@property (weak, nonatomic) WLWrap* wrap;

@property (weak, nonatomic) IBOutlet WLWrapView *wrapView;

@property (nonatomic, weak) id <WLStillPictureBaseViewControllerDelegate> delegate;

- (IBAction)selectWrap:(UIButton*)sender;

- (void)setupWrapView:(WLWrap *)wrap;

@end
