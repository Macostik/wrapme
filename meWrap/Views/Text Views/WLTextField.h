//
//  WLTextField.h
//  meWrap
//
//  Created by Ravenpod on 11/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLTextField : UITextField

@property (nonatomic) IBInspectable BOOL localize;
@property (nonatomic) IBInspectable BOOL disableSeparator;
@property (nonatomic) IBInspectable BOOL trim;

@property (nonatomic) IBInspectable NSString *preset;
@property (nonatomic) IBInspectable UIColor *strokeColor;

@end
