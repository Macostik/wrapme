//
//  WLEntryNotifyReceiver.h
//  wrapLive
//
//  Created by Sergey Maximenko on 5/6/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLEntryNotifier.h"

@interface WLEntryNotifyReceiver : NSObject <WLEntryNotifyReceiver>

@property (weak, nonatomic) WLEntry *containingEntry;

@property (weak, nonatomic) WLEntry *entry;

@property (strong, nonatomic) WLEntry *(^containingEntryBlock) (void);

@property (strong, nonatomic) WLEntry *(^entryBlock) (void);

@property (strong, nonatomic) BOOL (^shouldNotifyBlock) (WLEntry *entry);

@property (strong, nonatomic) WLObjectBlock addedBlock;

@property (strong, nonatomic) WLObjectBlock updatedBlock;

@property (strong, nonatomic) WLObjectBlock deletedBlock;

+ (instancetype)receiverWithEntry:(WLEntry *)entry;

@end
