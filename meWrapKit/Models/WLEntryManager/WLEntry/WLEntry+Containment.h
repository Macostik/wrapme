//
//  WLEntry+Containment.h
//  meWrap
//
//  Created by Ravenpod on 6/5/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLUser.h"
#import "WLDevice.h"
#import "WLWrap.h"
#import "WLCandy.h"
#import "WLComment.h"
#import "WLMessage.h"

@interface WLEntry (Containment)

@property (nonatomic) WLEntry* container;

+ (Class)containerClass;

+ (NSSet*)contentClasses;

+ (Class)entryClassByName:(NSString*)entryName;

+ (NSString*)name;

+ (NSString*)displayName;

+ (id)entryFromDictionaryRepresentation:(NSDictionary*)dictionary;

- (NSDictionary*)dictionaryRepresentation;

@end

@interface WLWrap (Containment)

@end

@interface WLCandy (Containment)

@end

@interface WLMessage (Containment)

@end

@interface WLComment (Containment)

@end
