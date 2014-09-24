//
//  WLWrapBroadcaster.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapBroadcaster.h"
#import "WLEntryManager.h"
#import "NSDate+Additions.h"

@interface WLWrapBroadcaster ()

@property (strong, nonatomic) WLBroadcastSelectReceiver wrapSelectBlock;

@property (strong, nonatomic) WLBroadcastSelectReceiver candySelectBlock;

@property (strong, nonatomic) WLBroadcastSelectReceiver messageSelectBlock;

@property (strong, nonatomic) WLBroadcastSelectReceiver commentSelectBlock;

@end

@implementation WLWrapBroadcaster

+ (instancetype)broadcaster {
    static id instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[self alloc] init];
	});
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        __weak typeof(self)weakSelf = self;
        self.wrapSelectBlock = ^BOOL (NSObject <WLWrapBroadcastReceiver> *receiver, WLWrap *wrap) {
            if ([receiver respondsToSelector:@selector(broadcasterPreferedWrap:)]) {
                return [[receiver broadcasterPreferedWrap:weakSelf] isEqualToEntry:wrap];
            }
            return YES;
        };
        self.candySelectBlock = ^BOOL (NSObject <WLWrapBroadcastReceiver> *receiver, WLCandy *candy) {
            if (candy.wrap && !weakSelf.wrapSelectBlock(receiver, candy.wrap)) {
                return NO;
            }
            if ([receiver respondsToSelector:@selector(broadcasterPreferedCandyType:)]) {
                if (![candy isCandyOfType:[receiver broadcasterPreferedCandyType:weakSelf]]) {
                    return NO;
                }
            }
            if ([receiver respondsToSelector:@selector(broadcasterPreferedCandy:)]) {
                if (![[receiver broadcasterPreferedCandy:weakSelf] isEqualToEntry:candy]) {
                    return NO;
                }
            }
            return YES;
        };
        self.messageSelectBlock = ^BOOL (NSObject <WLWrapBroadcastReceiver> *receiver, WLMessage *message) {
            if (message.wrap && !weakSelf.wrapSelectBlock(receiver, message.wrap)) {
                return NO;
            }
            return YES;
        };
        self.commentSelectBlock = ^BOOL (NSObject <WLWrapBroadcastReceiver> *receiver, WLComment *comment) {
            return weakSelf.candySelectBlock(receiver, comment.candy);
        };
    }
    return self;
}

- (void)broadcastUserChange:(WLUser *)user {
    [self broadcast:@selector(broadcaster:userChanged:) object:user];
}

- (void)broadcastWrapCreation:(WLWrap *)wrap {
	[self broadcast:@selector(broadcaster:wrapCreated:) object:wrap select:self.wrapSelectBlock];
}

- (void)broadcastWrapChange:(WLWrap *)wrap {
	[self broadcast:@selector(broadcaster:wrapChanged:) object:wrap select:self.wrapSelectBlock];
}

- (void)broadcastWrapRemoving:(WLWrap *)wrap {
	[self broadcast:@selector(broadcaster:wrapRemoved:) object:wrap select:self.wrapSelectBlock];
}

- (void)broadcastCandyCreation:(WLCandy *)candy {
	[self broadcast:@selector(broadcaster:candyCreated:) object:candy select:self.candySelectBlock];
}

- (void)broadcastCandyChange:(WLCandy *)candy {
	[self broadcast:@selector(broadcaster:candyChanged:) object:candy select:self.candySelectBlock];
}

- (void)broadcastCandyRemove:(WLCandy *)candy {
	[self broadcast:@selector(broadcaster:candyRemoved:) object:candy select:self.candySelectBlock];
}

- (void)broadcastMessageCreation:(WLMessage*)message {
    [self broadcast:@selector(broadcaster:messageCreated:) object:message select:self.messageSelectBlock];
}

- (void)broadcastMessageChange:(WLMessage*)message {
    [self broadcast:@selector(broadcaster:messageChanged:) object:message select:self.messageSelectBlock];
}

- (void)broadcastMessageRemove:(WLMessage*)message {
    [self broadcast:@selector(broadcaster:messageRemoved:) object:message select:self.messageSelectBlock];
}

- (void)broadcastCommentCreation:(WLComment *)comment {
	[self broadcast:@selector(broadcaster:commentCreated:) object:comment select:self.commentSelectBlock];
}

- (void)broadcastCommentChange:(WLComment *)comment {
	[self broadcast:@selector(broadcaster:commentChanged:) object:comment select:self.commentSelectBlock];
}

- (void)broadcastCommentRemove:(WLComment *)comment {
	[self broadcast:@selector(broadcaster:commentRemoved:) object:comment select:self.commentSelectBlock];
}

@end

@implementation WLEntry (WLWrapBroadcaster)

- (instancetype)update:(NSDictionary *)dictionary {
	[self API_setup:dictionary];
    if (self.hasChanges) [self broadcastChange];
	return self;
}

- (void)broadcastCreation {
	
}

- (void)broadcastChange {
	
}

- (void)broadcastRemoving {
	
}

@end

@implementation WLUser (WLWrapBroadcaster)

- (void)broadcastChange {
    [[WLWrapBroadcaster broadcaster] broadcastUserChange:self];
}

@end

@implementation WLWrap (WLWrapBroadcaster)

- (void)broadcastCreation {
    [[WLWrapBroadcaster broadcaster] broadcastWrapCreation:self];
}

- (void)broadcastChange {
    [[WLWrapBroadcaster broadcaster] broadcastWrapChange:self];
}

- (void)broadcastRemoving {
    [[WLWrapBroadcaster broadcaster] broadcastWrapRemoving:self];
}

@end

@implementation WLCandy (WLWrapBroadcaster)

- (void)broadcastCreation {
    [[WLWrapBroadcaster broadcaster] broadcastCandyCreation:self];
    WLWrap* wrap = self.wrap;
    if ([wrap.updatedAt earlier:self.updatedAt]) wrap.updatedAt = self.updatedAt;
    [wrap broadcastChange];
}

- (void)broadcastChange {
    [[WLWrapBroadcaster broadcaster] broadcastCandyChange:self];
    WLWrap* wrap = self.wrap;
    if ([wrap.updatedAt earlier:self.updatedAt]) wrap.updatedAt = self.updatedAt;
    [wrap broadcastChange];
}

- (void)broadcastRemoving {
    [[WLWrapBroadcaster broadcaster] broadcastCandyRemove:self];
    [self.wrap broadcastChange];
}

@end

@implementation WLMessage (WLWrapBroadcaster)

- (void)broadcastCreation {
    [[WLWrapBroadcaster broadcaster] broadcastMessageCreation:self];
    WLWrap* wrap = self.wrap;
    if ([wrap.updatedAt earlier:self.updatedAt]) wrap.updatedAt = self.updatedAt;
    [wrap broadcastChange];
}

- (void)broadcastChange {
    [[WLWrapBroadcaster broadcaster] broadcastMessageChange:self];
    WLWrap* wrap = self.wrap;
    if ([wrap.updatedAt earlier:self.updatedAt]) wrap.updatedAt = self.updatedAt;
    [wrap broadcastChange];
}

- (void)broadcastRemoving {
    [[WLWrapBroadcaster broadcaster] broadcastMessageRemove:self];
    [self.wrap broadcastChange];
}

@end

@implementation WLComment (WLWrapBroadcaster)

- (void)broadcastCreation {
    [[WLWrapBroadcaster broadcaster] broadcastCommentCreation:self];
    WLCandy* candy = self.candy;
    if ([candy.updatedAt earlier:self.updatedAt]) candy.updatedAt = self.updatedAt;
    [candy broadcastChange];
}

- (void)broadcastChange {
    [[WLWrapBroadcaster broadcaster] broadcastCommentChange:self];
    WLCandy* candy = self.candy;
    if ([candy.updatedAt earlier:self.updatedAt]) candy.updatedAt = self.updatedAt;
    [candy broadcastChange];
}

- (void)broadcastRemoving {
    [[WLWrapBroadcaster broadcaster] broadcastCommentRemove:self];
    [self.candy broadcastChange];
}

@end
