//
//  WLEntryView.h
//  meWrap
//
//  Created by Ravenpod on 2/6/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLEntryView : UIView <EntryNotifying>

@property (strong, nonatomic) id entry;

- (void)update:(id)entry;

@end
