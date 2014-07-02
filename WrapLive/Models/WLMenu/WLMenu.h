//
//  WLMenu.h
//  WrapLive
//
//  Created by Sergey Maximenko on 6/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLMenu;

@protocol WLMenuDelegate <NSObject>

- (NSString*)menu:(WLMenu*)menu titleForItem:(NSUInteger)item;

- (SEL)menu:(WLMenu*)menu actionForItem:(NSUInteger)item;

@optional

- (BOOL)menuShouldBePresented:(WLMenu*)menu;

- (NSUInteger)menuNumberOfItems:(WLMenu*)menu;

@end

@interface WLMenu : UIResponder

@property (weak, nonatomic) UIResponder<WLMenuDelegate> *delegate;

@property (nonatomic) BOOL vibrate;

+ (instancetype)menuWithView:(UIView*)view delegate:(UIResponder<WLMenuDelegate> *)delegate;

+ (void)hide;

@end
