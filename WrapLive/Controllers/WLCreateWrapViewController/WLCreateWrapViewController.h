//
//  WLCreateWrapViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 25.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLShakeViewController.h"
#import "WLStillPictureViewController.h"

@class WLWrap;
@class WLPicture;
@class WLCreateWrapViewController;

@protocol WLCreateWrapDelegate <NSObject>

@optional

- (void)wlCreateWrapViewController:(WLCreateWrapViewController *)viewController didCreateWrap:(WLWrap *)wrap;

@end

@interface WLCreateWrapViewController : WLShakeViewController <UITextFieldDelegate, WLStillPictureViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (strong, nonatomic) WLBlock cancelHandler;
@property (assign, nonatomic) id <WLCreateWrapDelegate> delegate;

- (void)removeAnimateViewFromSuperView;

@end


