//
//  WLEmailViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 11/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAuthorizationSceneViewController.h"

@class WLEmailViewController;

@protocol WLEmailViewControllerDelegate <WLAuthorizationSceneViewControllerDelegate>

- (void)emailViewController:(WLEmailViewController *)controller didFinishWithEmail:(NSString*)email;

@end

@interface WLEmailViewController : WLAuthorizationSceneViewController

@property (nonatomic, weak) id <WLEmailViewControllerDelegate> delegate;

@end
