//
//  WLProfileEditSession.m
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 6/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLProfileEditSession.h"

@interface WLProfileEditSessionEmailProperty : WLEditSessionProperty

@end

@implementation WLProfileEditSessionEmailProperty

- (void)apply:(id)value {
    
}

- (id)initialOriginalValue {
    return [WLAuthorization priorityEmail];
}

@end

@implementation WLProfileEditSession

- (instancetype)initWithUser:(WLEntry *)entry {
    NSMutableSet *properties = [NSMutableSet set];
    [properties addObject:[WLEditSessionProperty stringProperty:@"picture.large"]];
    [properties addObject:[WLEditSessionProperty stringProperty:@"name"]];
    [properties addObject:[WLProfileEditSessionEmailProperty stringProperty:@"email"]];
    return [super initWithEntry:entry properties:properties];
}

- (void)setName:(NSString *)name {
    [self changeValue:name forProperty:@"name"];
}

- (NSString *)name {
    return [self changedValueForProperty:@"name"];
}

- (void)setEmail:(NSString *)email {
    [self changeValue:email forProperty:@"email"];
}

- (NSString *)email {
    return [self changedValueForProperty:@"email"];
}

- (void)setUrl:(NSString *)url {
    [self changeValue:url forProperty:@"picture.large"];
}

- (NSString *)url {
    return [self changedValueForProperty:@"picture.large"];
}

- (BOOL)hasChangedName {
    return [self isPropertyChanged:@"name"];
}

- (BOOL)hasChangedEmail {
    return [self isPropertyChanged:@"email"];
}

- (BOOL)hasChangedUrl {
    return [self isPropertyChanged:@"picture.large"];
}

@end
