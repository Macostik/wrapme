//
//  WLEntryDescriptor.h
//  meWrap
//
//  Created by Sergey Maximenko on 9/25/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLEntryManager.h"

@class NSEntityDescription;

@interface WLEntryDescriptor : NSObject

@property (strong, nonatomic) NSString *identifier;

@property (strong, nonatomic) NSString *uploadIdentifier;

@property (strong, nonatomic) NSDictionary *data;

@property (strong, nonatomic) Class entryClass;

@property (strong, nonatomic) NSString *container;

- (BOOL)entryExists;

@end

@interface WLEntryManager (WLEntryDescriptor)

- (void)fetchEntries:(NSMutableDictionary *)descriptors;

@end
