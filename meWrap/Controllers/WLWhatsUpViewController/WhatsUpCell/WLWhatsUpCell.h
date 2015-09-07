//
//  WLWhatsUpCell.h
//  meWrap
//
//  Created by Ravenpod on 8/21/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEntryCell.h"

const static CGFloat WLWhatsUpCommentHorizontalSpacing = 144.0f;
const static CGFloat WLPaddingCell = 24.0;

@class WLWhatsUpEvent;

@interface WLWhatsUpCell : WLEntryCell

+ (CGFloat)additionalHeightCell:(WLWhatsUpEvent*)event;

@end

@interface WLCommentWhatsUpCell : WLWhatsUpCell

@end

@interface WLCandyWhatsUpCell : WLWhatsUpCell

@end
