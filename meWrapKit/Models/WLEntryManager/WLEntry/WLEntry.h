//
//  WLEntry.h
//  meWrap
//
//  Created by Ravenpod on 13.06.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "WLAsset.h"

@interface WLEntry : NSManagedObject

@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * uploadIdentifier;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) WLAsset * picture;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic) BOOL unread;

- (NSComparisonResult)compare:(WLEntry *)entry;

@end
