//
//  WLTestUserPicker.h
//  WrapLive
//
//  Created by Sergey Maximenko on 22.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLTestUserPicker : UITableView

+ (void)showInView:(UIView*)view selection:(void (^)(WLAuthorization* authorization))selection;

@end
