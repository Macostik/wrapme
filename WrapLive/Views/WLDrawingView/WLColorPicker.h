//
//  WLColorPicker.h
//  wrapLive
//
//  Created by Sergey Maximenko on 6/24/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLColorPicker;

@protocol WLColorPickerDelegate <NSObject>

- (void)colorPicker:(WLColorPicker*)picker pickedColor:(UIColor*)color;

@end

@interface WLColorPicker : UIView

@property (nonatomic, weak) IBOutlet id <WLColorPickerDelegate> delegate;

@end
