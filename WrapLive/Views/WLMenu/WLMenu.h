//
//  WLMenu.h
//  WrapLive
//
//  Created by Sergey Maximenko on 6/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLMenu;

typedef void (^WLMenuConfiguration)(WLMenu* menu, BOOL *vibrate);

@interface WLMenuItem : NSObject

@property (strong, nonatomic) UIImage* image;

@property (strong, nonatomic) WLBlock block;

@end

@interface WLMenu : UIView

@property (readonly, nonatomic) BOOL visible;

+ (instancetype)sharedMenu;

- (void)addView:(UIView*)view configuration:(WLMenuConfiguration)configuration;

- (void)hide;

- (WLMenuItem*)addItem:(WLBlock)block;

- (void)addItemWithImage:(UIImage*)image block:(WLBlock)block;

@end

@interface WLMenu (DefinedItems)

- (void)addDeleteItem:(WLBlock)block;

- (void)addLeaveItem:(WLBlock)block;

- (void)addReportItem:(WLBlock)block;

- (void)addDownloadItem:(WLBlock)block;

@end
