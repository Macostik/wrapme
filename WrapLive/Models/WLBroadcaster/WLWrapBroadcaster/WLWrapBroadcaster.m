//
//  WLWrapBroadcaster.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapBroadcaster.h"
#import "WLEntryManager.h"

@interface WLWrapBroadcaster ()

@property (strong, nonatomic) WLBroadcastSelectReceiver selectReceiverBlock;

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

- (WLBroadcastSelectReceiver)wrapSelectBlock:(WLWrap*)wrap {
    __weak typeof(self)weakSelf = self;
    return ^BOOL (NSObject <WLWrapBroadcastReceiver> *receiver) {
        if ([receiver respondsToSelector:@selector(broadcasterPreferedWrap:)]) {
            return [[receiver broadcasterPreferedWrap:weakSelf] isEqualToEntry:wrap];
        }
        return YES;
    };
}

- (WLBroadcastSelectReceiver)candySelectBlock:(WLCandy*)candy {
    __weak typeof(self)weakSelf = self;
    return ^BOOL (NSObject <WLWrapBroadcastReceiver> *receiver) {
        if (![weakSelf wrapSelectBlock:candy.wrap](receiver)) {
            return NO;
        }
        if ([receiver respondsToSelector:@selector(broadcasterPreferedCandy:)]) {
            if (![[receiver broadcasterPreferedCandy:weakSelf] isEqualToEntry:candy]) {
                return NO;
            }
        }
        return YES;
    };
}

- (void)broadcastWrapCreation:(WLWrap *)wrap {
	[self broadcast:@selector(broadcaster:wrapCreated:) object:wrap select:[self wrapSelectBlock:wrap]];
}

- (void)broadcastWrapChange:(WLWrap *)wrap {
	[self broadcast:@selector(broadcaster:wrapChanged:) object:wrap select:[self wrapSelectBlock:wrap]];
}

- (void)broadcastWrapRemoving:(WLWrap *)wrap {
	[self broadcast:@selector(broadcaster:wrapRemoved:) object:wrap select:[self wrapSelectBlock:wrap]];
}

- (void)broadcastCandyCreation:(WLCandy *)candy {
	[self broadcast:@selector(broadcaster:candyCreated:) object:candy select:[self candySelectBlock:candy]];
}

- (void)broadcastCandyChange:(WLCandy *)candy {
	[self broadcast:@selector(broadcaster:candyChanged:) object:candy select:[self candySelectBlock:candy]];
}

- (void)broadcastCandyRemove:(WLCandy *)candy {
	[self broadcast:@selector(broadcaster:candyRemoved:) object:candy select:[self candySelectBlock:candy]];
}

- (void)broadcastCommentCreation:(WLComment *)comment {
	[self broadcast:@selector(broadcaster:commentCreated:) object:comment];
}

- (void)broadcastCommentChange:(WLComment *)comment {
	[self broadcast:@selector(broadcaster:commentChanged:) object:comment];
}

- (void)broadcastCommentRemove:(WLComment *)comment {
	[self broadcast:@selector(broadcaster:commentRemoved:) object:comment];
}

@end

@implementation WLEntry (WLWrapBroadcaster)

- (instancetype)update:(NSDictionary *)dictionary {
	[self API_setup:dictionary];
	[self broadcastChange];
    [self save];
	return self;
}

- (void)broadcastCreation {
	
}

- (void)broadcastChange {
	
}

- (void)broadcastRemoving {
	
}

@end

@implementation WLWrap (WLWrapBroadcaster)

- (void)broadcastCreation {
    run_after(0.0, ^{
        [[WLWrapBroadcaster broadcaster] broadcastWrapCreation:self];
    });
}

- (void)broadcastChange {
    run_after(0.0, ^{
        [[WLWrapBroadcaster broadcaster] broadcastWrapChange:self];
    });
}

- (void)broadcastRemoving {
    run_after(0.0, ^{
        [[WLWrapBroadcaster broadcaster] broadcastWrapRemoving:self];
    });
}

@end

@implementation WLCandy (WLWrapBroadcaster)

- (void)broadcastCreation {
    run_after(0.0, ^{
        [[WLWrapBroadcaster broadcaster] broadcastCandyCreation:self];
    });
}

- (void)broadcastChange {
    run_after(0.0, ^{
        [[WLWrapBroadcaster broadcaster] broadcastCandyChange:self];
    });
}

- (void)broadcastRemoving {
    run_after(0.0, ^{
        [[WLWrapBroadcaster broadcaster] broadcastCandyRemove:self];
    });
}

@end

@implementation WLComment (WLWrapBroadcaster)

- (void)broadcastCreation {
    run_after(0.0, ^{
        [[WLWrapBroadcaster broadcaster] broadcastCommentCreation:self];
    });
}

- (void)broadcastChange {
    run_after(0.0, ^{
        [[WLWrapBroadcaster broadcaster] broadcastCommentChange:self];
    });
}

- (void)broadcastRemoving {
    run_after(0.0, ^{
        [[WLWrapBroadcaster broadcaster] broadcastCommentRemove:self];
    });
}

@end
