//
//  WLMenu.h
//  WrapLive
//
//  Created by Sergey Maximenko on 6/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLMenu;

@interface WLMenuItem : NSObject

@property (strong, nonatomic) UIImage* image;

@property (strong, nonatomic) NSString* title;

@property (strong, nonatomic) WLBlock block;

@end

@interface WLMenu : UIView

@property (nonatomic) BOOL vibrate;

@property (strong, nonatomic) BOOL (^configuration) (WLMenu *menu);

@property (weak, nonatomic) UIView* view;

+ (instancetype)menuWithView:(UIView*)view configuration:(BOOL (^)(WLMenu* menu))configuration;

+ (instancetype)menuWithView:(UIView*)view title:(NSString*)title block:(WLBlock)block;

+ (void)hide;

- (instancetype)initWithView:(UIView*)view configuration:(BOOL (^)(WLMenu* menu))configuration;

- (instancetype)initWithView:(UIView*)view title:(NSString*)title block:(WLBlock)block;

- (void)hide;

- (void)show;

- (void)show:(CGPoint)point;

- (WLMenuItem*)addItem:(WLBlock)block;

- (void)addItemWithTitle:(NSString*)title block:(WLBlock)block;

- (void)addItemWithImage:(UIImage*)image block:(WLBlock)block;

@end

@interface WLMenu (DefinedItems)

- (void)addDeleteItem:(WLBlock)block;

- (void)addLeaveItem:(WLBlock)block;

- (void)addReportItem:(WLBlock)block;

- (void)addDownloadItem:(WLBlock)block;

@end
