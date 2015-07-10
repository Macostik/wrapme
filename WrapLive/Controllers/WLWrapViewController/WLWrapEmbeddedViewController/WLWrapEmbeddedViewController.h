//
//  WLWrapEmbeddedViewController.h
//  wrapLive
//
//  Created by Sergey Maximenko on 7/10/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"

@class WLWrapEmbeddedViewController;

@protocol WLWrapEmbeddedViewControllerDelegate <NSObject>

@end

@interface WLWrapEmbeddedViewController : WLBaseViewController

@property (nonatomic, weak) id <WLWrapEmbeddedViewControllerDelegate> delegate;

@property (weak, nonatomic) WLWrap *wrap;

@end
