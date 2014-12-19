//
//  WLTextView.h
//  WrapLive
//
//  Created by Sergey Maximenko on 12/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE

@interface WLTextView : UITextView

@property (nonatomic) IBInspectable NSString *preset;

@property (strong, nonatomic) NSString *placeholder;

@end
