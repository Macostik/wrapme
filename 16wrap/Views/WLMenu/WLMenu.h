//
//  WLMenu.h
//  moji
//
//  Created by Ravenpod on 6/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLMenu;

typedef void(^WLMenuConfiguration)(WLMenu* menu);

@interface WLMenu : UIView

@property (readonly, nonatomic) BOOL visible;

@property (weak, nonatomic) WLEntry* entry;

@property (nonatomic) BOOL vibrate;

+ (instancetype)sharedMenu;

- (void)addView:(UIView*)view configuration:(WLMenuConfiguration)configuration;

- (void)hide;

- (void)addItemWithText:(NSString*)text block:(WLObjectBlock)block;

@end

@interface WLMenu (DefinedItems)

- (void)addDeleteItem:(WLObjectBlock)block;

- (void)addLeaveItem:(WLObjectBlock)block;

- (void)addReportItem:(WLObjectBlock)block;

- (void)addDownloadItem:(WLObjectBlock)block;

- (void)addCopyItem:(WLObjectBlock)block;

- (void)addEditPhotoItem:(WLObjectBlock)block;

- (void)addDrawPhotoItem:(WLObjectBlock)block;

@end
