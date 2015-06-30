//
//  WLPhotosViewController.h
//  
//
//  Created by Yura Granchenko on 10/06/15.
//
//

#import "WLBaseViewController.h"

@class WLPhotosViewController, WLBasicDataSource;

@protocol WLPhotosViewControllerDelegate <NSObject>

- (void)photosViewController:(WLPhotosViewController *)controller didTouchCameraButton:(WLBasicDataSource *)dataSource;

@end

@interface WLPhotosViewController : WLBaseViewController

@property (weak, nonatomic) WLWrap* wrap;

@property (nonatomic, weak) id <WLPhotosViewControllerDelegate> delegate;

@end
