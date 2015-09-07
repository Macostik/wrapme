//
//  WLEntryNotifyReceiver.h
//  meWrap
//
//  Created by Ravenpod on 5/6/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLEntryNotifier.h"

@interface WLEntryNotifyReceiver : NSObject <WLEntryNotifyReceiver>

@property (weak, nonatomic) WLEntry *container;

@property (weak, nonatomic) WLEntry *entry;

@property (strong, nonatomic) WLEntry *(^containerBlock) (void);

@property (strong, nonatomic) WLEntry *(^entryBlock) (void);

@property (strong, nonatomic) BOOL (^shouldNotifyBlock) (id entry);

@property (strong, nonatomic) WLObjectBlock willAddBlock;

@property (strong, nonatomic) WLObjectBlock didAddBlock;

@property (strong, nonatomic) WLObjectBlock willUpdateBlock;

@property (strong, nonatomic) WLObjectBlock didUpdateBlock;

@property (strong, nonatomic) WLObjectBlock willDeleteBlock;

@property (strong, nonatomic) WLObjectBlock didDeleteBlock;

@property (strong, nonatomic) WLObjectBlock willDeleteContainingBlock;

@property (strong, nonatomic) WLObjectBlock didDeleteContainingBlock;

+ (instancetype)receiverWithEntry:(WLEntry *)entry;

@end
