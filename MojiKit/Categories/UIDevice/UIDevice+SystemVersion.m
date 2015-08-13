//
//  UIDevice+SystemVersion.m
//  moji
//
//  Created by Ravenpod on 03.02.14.
//  Copyright (c) 2014 yo, gg. All rights reserved.
//

#import "UIDevice+SystemVersion.h"

@implementation UIDevice (SystemVersion)

- (NSComparisonResult)compareSystemVersion:(NSString*)version {
    return [[self systemVersion] compare:version options:NSNumericSearch];
}

- (BOOL)systemVersionEqualTo:(NSString*)version {
    return ([self compareSystemVersion:version] == NSOrderedSame);
}

- (BOOL)systemVersionSince:(NSString*)version {
    return ([self compareSystemVersion:version] != NSOrderedAscending);
}

- (BOOL)systemVersionBefore:(NSString*)version {
    return ([self compareSystemVersion:version] == NSOrderedAscending);
}

@end
