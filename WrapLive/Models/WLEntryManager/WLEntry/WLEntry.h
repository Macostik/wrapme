//
//  WLEntry.h
//  WrapLive
//
//  Created by Sergey Maximenko on 13.06.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "WLPicture.h"

@interface WLEntry : NSManagedObject

@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) WLPicture * picture;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSNumber * unread;

@end
