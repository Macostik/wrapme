//
//  WLMessageGroupCell.h
//  WrapLive
//
//  Created by Sergey Maximenko on 09.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

@class WLGroup;

@interface WLMessageGroupCell : UICollectionReusableView

@property (strong, nonatomic) WLGroup* group;

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@end
