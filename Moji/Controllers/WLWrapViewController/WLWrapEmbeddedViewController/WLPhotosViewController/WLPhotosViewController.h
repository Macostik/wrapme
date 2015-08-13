//
//  WLPhotosViewController.h
//  
//
//  Created by Yura Granchenko on 10/06/15.
//
//

#import "WLWrapEmbeddedViewController.h"

@class WLPhotosViewController;

@protocol WLPhotosViewControllerDelegate <WLWrapEmbeddedViewControllerDelegate>

@optional
- (void)photosViewControllerDidAddPhoto:(WLPhotosViewController *)controller;

@end

@interface WLPhotosViewController : WLWrapEmbeddedViewController

@property (nonatomic, weak) id <WLPhotosViewControllerDelegate> delegate;

@end
