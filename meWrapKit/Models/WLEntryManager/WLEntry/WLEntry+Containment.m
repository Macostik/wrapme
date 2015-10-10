//
//  WLEntry+Containment.m
//  meWrap
//
//  Created by Ravenpod on 6/5/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEntry+Containment.h"
#import "WLEntryManager.h"
#import "WLLocalization.h"

@implementation WLEntry (Containment)

+ (Class)containerClass {
    return nil;
}

+ (NSSet*)contentClasses {
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
    return NSStringFromClass([self class]);
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

- (WLEntry*)container {
    return nil;
}

- (void)setContainer:(WLEntry *)container {
    
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

@end

@implementation WLWrap (Containment)

+ (NSSet *)contentClasses {
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

+ (Class)containerClass {
    return [WLWrap class];
}

+ (NSSet *)contentClasses {
    return [NSSet setWithObjects:[WLComment class], nil];
}

+ (NSString *)name {
    return WLCandyKey;
}

+ (NSString *)displayName {
    return WLLS(@"photo");
}

- (WLEntry *)container {
    return self.wrap;
}

- (void)setContainer:(WLEntry *)container {
    if (container && self.wrap != container) {
        self.wrap = (id)container;
    }
}

@end

@implementation WLMessage (Containment)

+ (Class)containerClass {
    return [WLWrap class];
}

+ (NSString *)name {
    return WLMessageKey;
}

+ (NSString *)displayName {
    return WLLS(@"message");
}

- (WLEntry *)container {
    return self.wrap;
}

- (void)setContainer:(WLEntry *)container {
    if (container && self.wrap != container) {
        self.wrap = (id)container;
    }
}

@end

@implementation WLComment (Containment)

+ (Class)containerClass {
    return [WLCandy class];
}

+ (NSString *)name {
    return WLCommentKey;
}

+ (NSString *)displayName {
    return WLLS(@"comment");
}

- (WLEntry *)container {
    return self.candy;
}

- (void)setContainer:(WLEntry *)container {
    if (container && self.candy != container) {
        self.candy = (id)container;
    }
}

@end
