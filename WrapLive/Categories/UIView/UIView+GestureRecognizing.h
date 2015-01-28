//
//  UIView+GestureRecognizing.h
//  WrapLive
//
//  Created by Sergey Maximenko on 12.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (GestureRecognizing)

- (void)removeGestureRecognizerWithIdentifier:(NSString*)identifier;

@end

@interface UIGestureRecognizer (Helper)

@property (strong, nonatomic) WLGestureBlock gestureBlock;

@property (strong, nonatomic) NSString* identifier;

+ (instancetype)recognizerWithView:(UIView*)view block:(WLGestureBlock)block;

+ (instancetype)recognizerWithView:(UIView*)view identifier:(NSString*)identifier block:(WLGestureBlock)block;

- (instancetype)initWithView:(UIView*)view block:(WLGestureBlock)block;

- (instancetype)initWithView:(UIView*)view identifier:(NSString*)identifier block:(WLGestureBlock)block;

@end
