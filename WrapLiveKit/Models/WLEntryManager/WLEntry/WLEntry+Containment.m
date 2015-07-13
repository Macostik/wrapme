//
//  WLEntry+Containment.m
//  wrapLive
//
//  Created by Sergey Maximenko on 6/5/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEntry+Containment.h"
#import "WLEntryManager.h"

@implementation WLEntry (Containment)

+ (Class)containingEntryClass {
    return nil;
}

+ (NSSet*)containedEntryClasses {
    return nil;
}

+ (Class)entryClassByName:(NSString*)entryName {
    if ([entryName isEqualToString:WLCandyKey]) {
        return [WLCandy class];
    } else if ([entryName isEqualToString:WLWrapKey])  {
        return [WLWrap class];
    } else if ([entryName isEqualToString:WLCommentKey])  {
        return [WLComment class];
    } else  if ([entryName isEqualToString:WLMessageKey])  {
        return [WLMessage class];
    } else {
        return nil;
    }
}

+ (NSString*)name {
    return nil;
}

+ (NSString*)displayName {
    return @"Item";
}

+ (id)entryFromDictionaryRepresentation:(NSDictionary *)dictionary {
    NSString *name = dictionary[@"name"];
    NSString *identifier = dictionary[@"identifier"];
    if (name.nonempty && identifier.nonempty) {
        Class entryClass = [self entryClassByName:name];
        if ([entryClass entryExists:identifier]) {
            return [entryClass entry:identifier];
        }
    }
    return nil;
}

- (WLEntry*)containingEntry {
    return nil;
}

- (void)setContainingEntry:(WLEntry *)containingEntry {
    
}

- (NSDictionary *)dictionaryRepresentation {
    NSString *name = [[self class] name];
    NSString *identifier = [self identifier];
    if (name.nonempty && identifier.nonempty) {
        return @{@"name":name,@"identifier":identifier};
    } else {
        return nil;
    }
}

- (WLWrap*)tryFindWrap {
    if ([self respondsToSelector:@selector(wrap)]) {
        return [(id)self wrap];
    }
    return [self.containingEntry tryFindWrap];
}

@end

@implementation WLWrap (Containment)

+ (NSSet *)containedEntryClasses {
    return [NSSet setWithObjects:[WLCandy class], [WLMessage class], nil];
}

+ (NSString *)name {
    return WLWrapKey;
}

+ (NSString *)displayName {
    return WLLS(@"wrap");
}

@end

@implementation WLCandy (Containment)

+ (Class)containingEntryClass {
    return [WLWrap class];
}

+ (NSSet *)containedEntryClasses {
    return [NSSet setWithObjects:[WLComment class], nil];
}

+ (NSString *)name {
    return WLCandyKey;
}

+ (NSString *)displayName {
    return WLLS(@"photo");
}

- (WLEntry *)containingEntry {
    return self.wrap;
}

- (void)setContainingEntry:(WLEntry *)containingEntry {
    if (containingEntry && self.wrap != containingEntry) {
        self.wrap = (id)containingEntry;
    }
}

@end

@implementation WLMessage (Containment)

+ (Class)containingEntryClass {
    return [WLWrap class];
}

+ (NSString *)name {
    return WLMessageKey;
}

+ (NSString *)displayName {
    return WLLS(@"message");
}

- (WLEntry *)containingEntry {
    return self.wrap;
}

- (void)setContainingEntry:(WLEntry *)containingEntry {
    if (containingEntry && self.wrap != containingEntry) {
        self.wrap = (id)containingEntry;
    }
}

@end

@implementation WLComment (Containment)

+ (Class)containingEntryClass {
    return [WLCandy class];
}

+ (NSString *)name {
    return WLCommentKey;
}

+ (NSString *)displayName {
    return WLLS(@"comment");
}

- (WLEntry *)containingEntry {
    return self.candy;
}

- (void)setContainingEntry:(WLEntry *)containingEntry {
    if (containingEntry && self.candy != containingEntry) {
        self.candy = (id)containingEntry;
    }
}

@end
