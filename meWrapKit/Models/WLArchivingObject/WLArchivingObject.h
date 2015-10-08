//
//  WLArchivingObject.h
//  meWrap
//
//  Created by Ravenpod on 21.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLArchivingObject : NSObject <NSCoding, NSCopying>

+ (NSSet*)archivableProperties;

- (instancetype)updateWithObject:(id)object;

@end

@interface NSObject (WLArchivingObject)

- (NSData*)archive;

+ (id)unarchive:(NSData*)data;

@end
