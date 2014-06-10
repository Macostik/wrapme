//
//  WLWrapBroadcaster.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapBroadcaster.h"

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
        if ([receiver respondsToSelector:@selector(broadcasterPreferedCandy:)]) {
            return [[receiver broadcasterPreferedCandy:weakSelf] isEqualToEntry:candy];
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

@implementation WLWrap (WLWrapBroadcaster)

- (void)broadcastCreation {
    [[WLWrapBroadcaster broadcaster] broadcastWrapCreation:self];
//	[[WLWrapBroadcaster broadcaster] performSelector:@selector(broadcastWrapCreation:) withObject:self afterDelay:0.0f];
}

- (void)broadcastChange {
    [[WLWrapBroadcaster broadcaster] broadcastWrapChange:self];
//	[[WLWrapBroadcaster broadcaster] performSelector:@selector(broadcastWrapChange:) withObject:self afterDelay:0.0f];
}

- (void)broadcastRemoving {
    [[WLWrapBroadcaster broadcaster] broadcastWrapRemoving:self];
//	[[WLWrapBroadcaster broadcaster] performSelector:@selector(broadcastWrapRemoving:) withObject:self afterDelay:0.0f];
}

@end

@implementation WLCandy (WLWrapBroadcaster)

- (void)broadcastCreation {
    [[WLWrapBroadcaster broadcaster] broadcastCandyCreation:self];
//	[[WLWrapBroadcaster broadcaster] performSelector:@selector(broadcastCandyCreation:) withObject:self afterDelay:0.0f];
}

- (void)broadcastChange {
    [[WLWrapBroadcaster broadcaster] broadcastCandyChange:self];
//	[[WLWrapBroadcaster broadcaster] performSelector:@selector(broadcastCandyChange:) withObject:self afterDelay:0.0f];
}

- (void)broadcastRemoving {
    [[WLWrapBroadcaster broadcaster] broadcastCandyRemove:self];
//	[[WLWrapBroadcaster broadcaster] performSelector:@selector(broadcastCandyRemove:) withObject:self afterDelay:0.0f];
}

@end

@implementation WLComment (WLWrapBroadcaster)

- (void)broadcastCreation {
	[[WLWrapBroadcaster broadcaster] performSelector:@selector(broadcastCommentCreation:) withObject:self afterDelay:0.0f];
}

- (void)broadcastChange {
	[[WLWrapBroadcaster broadcaster] performSelector:@selector(broadcastCommentChange:) withObject:self afterDelay:0.0f];
}

- (void)broadcastRemoving {
	[[WLWrapBroadcaster broadcaster] performSelector:@selector(broadcastCommentRemove:) withObject:self afterDelay:0.0f];
}

@end
