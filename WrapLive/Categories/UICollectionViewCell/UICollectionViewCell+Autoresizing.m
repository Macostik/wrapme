//
//  UICollectionViewCell+Autoresizing.m
//  WrapLive
//
//  Created by Sergey Maximenko on 10/9/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "UICollectionViewCell+Autoresizing.h"

@implementation UICollectionViewCell (Autoresizing)

-(void)awakeFromNib {
    self.contentView.frame = self.bounds;
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

@end
