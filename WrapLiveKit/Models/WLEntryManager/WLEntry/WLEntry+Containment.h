//
//  WLEntry+Containment.h
//  wrapLive
//
//  Created by Sergey Maximenko on 6/5/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEntry+Extended.h"
#import "WLUser+Extended.h"
#import "WLDevice+Extended.h"
#import "WLWrap+Extended.h"
#import "WLCandy+Extended.h"
#import "WLComment+Extended.h"
#import "WLContribution+Extended.h"
#import "WLUploading+Extended.h"
#import "WLMessage+Extended.h"

@interface WLEntry (Containment)

@property (nonatomic) WLEntry* containingEntry;

+ (Class)containingEntryClass;

+ (NSSet*)containedEntryClasses;

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
