//
//  WLMenu.h
//  WrapLive
//
//  Created by Sergey Maximenko on 6/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLMenu;

typedef WLEntry *(^WLMenuConfiguration)(WLMenu* menu, BOOL *vibrate);

@interface WLMenuItem : NSObject

@property (strong, nonatomic) UIImage* image;

@property (strong, nonatomic) WLObjectBlock block;

@end

@interface WLMenu : UIView

@property (readonly, nonatomic) BOOL visible;

@property (weak, nonatomic) WLEntry* entry;

+ (instancetype)sharedMenu;

- (void)addView:(UIView*)view configuration:(WLMenuConfiguration)configuration;

- (void)hide;

- (WLMenuItem*)addItem:(WLObjectBlock)block;

- (void)addItemWithImage:(UIImage*)image block:(WLObjectBlock)block;

@end

@interface WLMenu (DefinedItems)

- (void)addDeleteItem:(WLObjectBlock)block;

- (void)addLeaveItem:(WLObjectBlock)block;

- (void)addReportItem:(WLObjectBlock)block;

- (void)addDownloadItem:(WLObjectBlock)block;

@end
