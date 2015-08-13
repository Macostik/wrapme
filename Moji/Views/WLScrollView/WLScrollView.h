//
//  WLScrollView.h
//  moji
//
//  Created by Yura Granchenko on 26/01/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLScrollView : UIScrollView <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIView* zoomingView;

@end
