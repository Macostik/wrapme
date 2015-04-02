//
//  UIDevice+SystemVersion.m
//  Pressgram
//
//  Created by Sergey Maximenko on 03.02.14.
//  Copyright (c) 2014 yo, gg. All rights reserved.
//

#import "UIDevice+SystemVersion.h"

@implementation UIDevice (SystemVersion)

- (NSComparisonResult)compareSystemVersion:(NSString*)version
{
    return [[self systemVersion] compare:version options:NSNumericSearch];
}

- (BOOL)systemVersionEqualTo:(NSString*)version
{
    return ([self compareSystemVersion:version] == NSOrderedSame);
}

- (BOOL)systemVersionGreaterThan:(NSString*)version
{
    return ([self compareSystemVersion:version] == NSOrderedDescending);
}

- (BOOL)systemVersionGreaterThanOrEqualTo:(NSString*)version
{
    return ([self compareSystemVersion:version] != NSOrderedAscending);
}

- (BOOL)systemVersionLessThan:(NSString*)version
{
    return ([self compareSystemVersion:version] == NSOrderedAscending);
}

- (BOOL)systemVersionLessThanOrEqualTo:(NSString*)version
{
    return ([self compareSystemVersion:version] != NSOrderedDescending);
}

@end
