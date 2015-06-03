//
//  WLShapeView.h
//  wrapLive
//
//  Created by Sergey Maximenko on 6/2/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLShapeView : UIView

- (void)defineShapePath:(UIBezierPath*)path contentMode:(UIViewContentMode)contentMode;

@end