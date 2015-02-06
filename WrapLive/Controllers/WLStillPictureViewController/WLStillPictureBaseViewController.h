//
//  WLStillPictureBaseViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 2/6/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WLStillPictureMode.h"

@class WLStillPictureBaseViewController;
@class WLWrap;
@class WLWrapView;

@protocol WLStillPictureBaseViewControllerDelegate <NSObject>

@optional

- (void)stillPictureViewController:(WLStillPictureBaseViewController*)controller didSelectWrap:(WLWrap*)wrap;

@end

@interface WLStillPictureBaseViewController : UIViewController <WLStillPictureBaseViewControllerDelegate>

@property (nonatomic) WLStillPictureMode mode;

@property (strong, nonatomic) WLWrap* wrap;

@property (weak, nonatomic) IBOutlet WLWrapView *wrapView;

@property (nonatomic, weak) id <WLStillPictureBaseViewControllerDelegate> delegate;

- (IBAction)selectWrap:(UIButton*)sender;

- (void)setupWrapView:(WLWrap *)wrap;

@end
