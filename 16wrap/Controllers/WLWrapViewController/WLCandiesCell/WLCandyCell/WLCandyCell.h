//
//  WLWrapCandyCell.h
//  moji
//
//  Created by Ravenpod on 26.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "StreamReusableView.h"

@interface WLCandyCell : StreamReusableView

@property (nonatomic) IBInspectable BOOL disableMenu;

@property (weak, nonatomic, readonly) WLImageView *coverView;

@end
