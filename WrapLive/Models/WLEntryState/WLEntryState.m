//
//  WLEntryState.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEntryState.h"
#import "WLBlocks.h"
#import "NSString+Additions.h"

@implementation WLEntryState

+ (NSMutableDictionary*)states {
    static NSMutableDictionary* states = nil;
    if (states == nil) {
        states = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"WLEntryState"]];
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
				states = nil;
			}];
		});
    }
    return states;
}

+ (void)saveStates {
	[[NSUserDefaults standardUserDefaults] setObject:[self states] forKey:@"WLEntryState"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSDictionary *)stateWithEntry:(WLEntry *)entry {
	if (entry.identifier.nonempty) {
		return [[self states] dictionaryForKey:entry.identifier];
	}
	return nil;
}

+ (void)setState:(NSDictionary*)state withEntry:(WLEntry*)entry {
	if (entry.identifier.nonempty) {
		[[self states] setObject:state forKey:entry.identifier];
		[self saveStates];
	}
}

+ (BOOL)read:(WLEntry*)entry {
	NSNumber *read = [[self stateWithEntry:entry] objectForKey:@"read"];
	return read ? [read boolValue] : NO;
}

+ (BOOL)updated:(WLEntry*)entry {
	return [[self stateWithEntry:entry] boolForKey:@"updated"];
}

+ (void)getState:(WLEntry*)entry completion:(void (^)(BOOL read, BOOL updated))completion {
	NSDictionary* state = [self stateWithEntry:entry];
	NSNumber *read = [state objectForKey:@"read"];
	completion(read ? [read boolValue] : NO, [state boolForKey:@"updated"]);
}

+ (void)setRead:(BOOL)read entry:(WLEntry*)entry {
	NSMutableDictionary* state = [NSMutableDictionary dictionaryWithDictionary:[self stateWithEntry:entry]];
	[state setObject:@(read) forKey:@"read"];
	[self setState:state withEntry:entry];
}

+ (void)setUpdated:(BOOL)updated entry:(WLEntry*)entry {
	NSMutableDictionary* state = [NSMutableDictionary dictionaryWithDictionary:[self stateWithEntry:entry]];
	[state setObject:@(updated) forKey:@"updated"];
	[self setState:state withEntry:entry];
}

+ (void)setRead:(BOOL)read updated:(BOOL)updated entry:(WLEntry*)entry {
	NSMutableDictionary* state = [NSMutableDictionary dictionaryWithDictionary:[self stateWithEntry:entry]];
	[state setObject:@(read) forKey:@"read"];
	[state setObject:@(updated) forKey:@"updated"];
	[self setState:state withEntry:entry];
}

@end

@implementation WLEntry (WLEntryState)

- (BOOL)read {
	return [WLEntryState read:self];
}

- (BOOL)updated {
	return [WLEntryState updated:self];
}

- (void)getState:(void (^)(BOOL read, BOOL updated))completion {
	[WLEntryState getState:self completion:completion];
}

- (void)setRead:(BOOL)read {
	[WLEntryState setRead:read entry:self];
}

- (void)setUpdated:(BOOL)updated {
	[WLEntryState setUpdated:updated entry:self];
}

- (void)setRead:(BOOL)read updated:(BOOL)updated {
	[WLEntryState setRead:read updated:updated entry:self];
}

@end
