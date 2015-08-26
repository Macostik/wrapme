//
//  WLWrapView.h
//  moji
//
//  Created by Ravenpod on 2/6/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEntryView.h"

@class WLWrapStatusImageView;

@interface WLWrapView : WLEntryView

@property (weak, nonatomic) IBOutlet WLWrapStatusImageView *coverView;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

- (void)update:(WLWrap*)wrap;

@end
