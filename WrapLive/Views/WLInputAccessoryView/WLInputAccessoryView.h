//
//  WLInputAccessoryView.h
//  WrapLive
//
//  Created by Sergey Maximenko on 25.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLInputAccessoryView : UIControl

+ (instancetype)inputAccessoryViewWithResponder:(UIResponder*)responder;

+ (instancetype)inputAccessoryViewWithTarget:(id)target cancel:(SEL)cancel done:(SEL)done;

@property (weak, nonatomic) UIResponder *responder;

@end
