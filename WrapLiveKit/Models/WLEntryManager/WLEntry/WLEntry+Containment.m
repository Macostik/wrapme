//
//  WLEntry+Containment.m
//  wrapLive
//
//  Created by Sergey Maximenko on 6/5/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEntry+Containment.h"

@implementation WLEntry (Containment)

+ (Class)containingEntryClass {
    return nil;
}

+ (NSSet*)containedEntryClasses {
    return nil;
}

- (WLEntry*)containingEntry {
    return nil;
}

- (void)setContainingEntry:(WLEntry *)containingEntry {
    
}

@end

@implementation WLWrap (Containment)

+ (NSSet *)containedEntryClasses {
    return [NSSet setWithObjects:[WLCandy class], [WLMessage class], nil];
}

@end

@implementation WLCandy (Containment)

+ (Class)containingEntryClass {
    return [WLWrap class];
}

+ (NSSet *)containedEntryClasses {
    return [NSSet setWithObjects:[WLComment class], nil];
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

- (WLEntry *)containingEntry {
    return self.candy;
}

- (void)setContainingEntry:(WLEntry *)containingEntry {
    if (containingEntry && self.candy != containingEntry) {
        self.candy = (id)containingEntry;
    }
}

@end
