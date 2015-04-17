//
//  WLIconView.h
//  wrapLive
//
//  Created by Sergey Maximenko on 4/17/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLLabel.h"

@interface WLIconView : WLLabel

@property (strong, nonatomic) IBInspectable NSString *iconName;

@property (strong, nonatomic) IBInspectable UIColor *iconColor;

@property (strong, nonatomic) IBInspectable NSString *iconPreset;

@end
