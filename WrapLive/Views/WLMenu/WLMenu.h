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

@property (strong, nonatomic) NSString* text;

@property (strong, nonatomic) WLObjectBlock block;

@end

@interface WLMenu : UIView

@property (readonly, nonatomic) BOOL visible;

@property (weak, nonatomic) WLEntry* entry;

+ (instancetype)sharedMenu;

- (void)addView:(UIView*)view configuration:(WLMenuConfiguration)configuration;

- (void)hide;

- (WLMenuItem*)addItem:(WLObjectBlock)block;

- (void)addItemWithText:(NSString*)text block:(WLObjectBlock)block;

@end

@interface WLMenu (DefinedItems)

- (void)addDeleteItem:(WLObjectBlock)block;

- (void)addLeaveItem:(WLObjectBlock)block;

- (void)addReportItem:(WLObjectBlock)block;

- (void)addDownloadItem:(WLObjectBlock)block;

- (void)addCopyItem:(WLObjectBlock)block;

- (void)addEditPhotoItem:(WLObjectBlock)block;

@end
