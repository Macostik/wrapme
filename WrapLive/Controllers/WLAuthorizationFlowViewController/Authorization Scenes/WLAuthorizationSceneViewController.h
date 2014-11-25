//
//  WLAuthorizationSceneViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 11/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"

@class WLAuthorizationSceneViewController;

@protocol WLAuthorizationSceneViewControllerDelegate <NSObject>

@end

@interface WLAuthorizationSceneViewController : WLBaseViewController

@property (nonatomic, weak) id <WLAuthorizationSceneViewControllerDelegate> delegate;

@end
