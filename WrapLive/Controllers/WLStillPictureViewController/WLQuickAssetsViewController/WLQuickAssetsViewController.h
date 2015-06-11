//
//  WLQuickAssetsViewController.h
//  wrapLive
//
//  Created by Sergey Maximenko on 6/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WLAssetsViewController.h"

@interface WLQuickAssetsViewController : UIViewController

@property (weak, nonatomic) id <WLAssetsViewControllerDelegate> delegate;

@end
