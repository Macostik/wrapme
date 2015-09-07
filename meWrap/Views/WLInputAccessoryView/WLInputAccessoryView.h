//
//  WLInputAccessoryView.h
//  meWrap
//
//  Created by Ravenpod on 25.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLInputAccessoryView : UIControl

+ (instancetype)inputAccessoryViewWithResponder:(UIResponder*)responder;

+ (instancetype)inputAccessoryViewWithTarget:(id)target cancel:(SEL)cancel done:(SEL)done;

@property (weak, nonatomic) UIResponder *responder;

@end
