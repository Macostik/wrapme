//
//  WLTextView.h
//  meWrap
//
//  Created by Ravenpod on 12/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLTextView : UITextView

@property (nonatomic) IBInspectable NSString *preset;

@property (strong, nonatomic) NSString *placeholder;

@end
