//
//  PGProgressBar.h
//  PressGram-iOS
//
//  Created by Nikolay Rybalko on 6/21/13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLProgressBar : UIView

@property (nonatomic) float progress;

- (void)setProgress:(float)progress animated:(BOOL)animated;

@end


