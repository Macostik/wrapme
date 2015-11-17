//
//  WLMediaViewController.h
//  
//
//  Created by Yura Granchenko on 10/06/15.
//
//

#import "WLWrapEmbeddedViewController.h"

@class WLMediaViewController;

@protocol WLMediaViewControllerDelegate <WLWrapEmbeddedViewControllerDelegate>

@optional
- (void)mediaViewControllerDidAddPhoto:(WLMediaViewController *)controller;

- (void)mediaViewControllerDidOpenLiveBroadcast:(WLMediaViewController *)controller;

@end

@interface WLMediaViewController : WLWrapEmbeddedViewController

@property (nonatomic, weak) id <WLMediaViewControllerDelegate> delegate;

@end
