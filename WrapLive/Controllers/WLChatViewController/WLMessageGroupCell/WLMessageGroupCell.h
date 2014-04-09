//
//  WLMessageGroupCell.h
//  WrapLive
//
//  Created by Sergey Maximenko on 09.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

@class WLWrapDate;

@interface WLMessageGroupCell : UITableViewHeaderFooterView

+ (NSString*)reuseIdentifier;

@property (strong, nonatomic) WLWrapDate* date;

@end
