//
//  WLUser.h
//  meWrap
//
//  Created by Ravenpod on 7/9/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "WLEntry.h"

@class WLCandy, WLContribution, WLDevice, WLWrap;

@interface WLUser : WLEntry

@property (nonatomic) BOOL current;
@property (nonatomic) BOOL firstTimeUse;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *contributions;
@property (nonatomic, retain) NSSet *devices;
@property (nonatomic, retain) NSSet *editings;
@property (nonatomic, retain) NSSet *wraps;

@property (strong, nonatomic) NSString *phones;
@property (strong, nonatomic) NSString *securePhones;

@end

@interface WLUser (CoreDataGeneratedAccessors)

- (void)addContributionsObject:(WLContribution *)value;
- (void)removeContributionsObject:(WLContribution *)value;
- (void)addContributions:(NSSet *)values;
- (void)removeContributions:(NSSet *)values;

- (void)addDevicesObject:(WLDevice *)value;
- (void)removeDevicesObject:(WLDevice *)value;
- (void)addDevices:(NSSet *)values;
- (void)removeDevices:(NSSet *)values;

- (void)addEditingsObject:(WLCandy *)value;
- (void)removeEditingsObject:(WLCandy *)value;
- (void)addEditings:(NSSet *)values;
- (void)removeEditings:(NSSet *)values;

- (void)addWrapsObject:(WLWrap *)value;
- (void)removeWrapsObject:(WLWrap *)value;
- (void)addWraps:(NSSet *)values;
- (void)removeWraps:(NSSet *)values;

@end
