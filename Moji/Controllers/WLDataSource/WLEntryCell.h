//
//  WLEntryCell.h
//  moji
//
//  Created by Ravenpod on 7/30/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WLEntrySetup.h"

@interface WLEntryCell : UICollectionViewCell <WLEntrySetup>

+ (BOOL)isEmbeddedLongPress;

@end
