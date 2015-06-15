//
//  WLCommentsViewController.h
//  
//
//  Created by Yura Granchenko on 28/01/15.
//
//

#import "WLBaseViewController.h"

@interface WLCommentsViewController : WLBaseViewController

@property (weak, nonatomic) WLCandy *candy;

- (void)presentAsChildForParentViewController:(UIViewController *)parentViewContrller;

@end
