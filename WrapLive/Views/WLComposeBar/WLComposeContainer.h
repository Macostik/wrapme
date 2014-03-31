//
//  WLComposeContriner.h
//  WrapLive
//
//  Created by Sergey Maximenko on 31.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLComposeContainer : UIView

@property (nonatomic) BOOL editing;

- (void)setEditing:(BOOL)editing animated:(BOOL)animated;

@end
