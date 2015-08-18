//
//  WLEntrySetup.h
//  moji
//
//  Created by Ravenpod on 1/14/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol WLEntrySetup <NSObject>

@property (strong, nonatomic) id entry;

@property (strong, nonatomic) WLObjectBlock selectionBlock;

- (void)setup:(id)entry;

- (void)resetup;

- (void)select:(id)entry;

@end
