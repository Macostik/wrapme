//
//  WLEntryView.h
//  WrapLive
//
//  Created by Sergey Maximenko on 2/6/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WLEntryNotifier.h"

@interface WLEntryView : UIView <WLEntryNotifyReceiver>

@property (strong, nonatomic) id entry;

- (void)update:(id)entry;

@end
