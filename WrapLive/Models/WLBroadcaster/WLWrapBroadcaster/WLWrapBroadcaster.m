//
//  WLWrapBroadcaster.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapBroadcaster.h"

@interface WLWrapBroadcaster ()

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

- (void)broadcastWrapCreation:(WLWrap *)wrap {
	[self broadcast:@selector(broadcaster:wrapCreated:) object:wrap];
}

- (void)broadcastWrapChange:(WLWrap *)wrap {
	[self broadcast:@selector(broadcaster:wrapChanged:) object:wrap];
}

- (void)broadcastWrapRemoving:(WLWrap *)wrap {
	[self broadcast:@selector(broadcaster:wrapRemoved:) object:wrap];
}

- (void)broadcastCandyCreation:(WLCandy *)candy {
	[self broadcast:@selector(broadcaster:candyCreated:) object:candy];
}

- (void)broadcastCandyChange:(WLCandy *)candy {
	[self broadcast:@selector(broadcaster:candyChanged:) object:candy];
}

- (void)broadcastCandyRemove:(WLCandy *)candy {
	[self broadcast:@selector(broadcaster:candyRemoved:) object:candy];
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
	[[WLWrapBroadcaster broadcaster] performSelector:@selector(broadcastWrapCreation:) withObject:self afterDelay:0.0f];
}

- (void)broadcastChange {
	[[WLWrapBroadcaster broadcaster] performSelector:@selector(broadcastWrapChange:) withObject:self afterDelay:0.0f];
}

- (void)broadcastRemoving {
	[[WLWrapBroadcaster broadcaster] performSelector:@selector(broadcastWrapRemoving:) withObject:self afterDelay:0.0f];
}

@end

@implementation WLCandy (WLWrapBroadcaster)

- (void)broadcastCreation {
	[[WLWrapBroadcaster broadcaster] performSelector:@selector(broadcastCandyCreation:) withObject:self afterDelay:0.0f];
}

- (void)broadcastChange {
	[[WLWrapBroadcaster broadcaster] performSelector:@selector(broadcastCandyChange:) withObject:self afterDelay:0.0f];
}

- (void)broadcastRemoving {
	[[WLWrapBroadcaster broadcaster] performSelector:@selector(broadcastCandyRemove:) withObject:self afterDelay:0.0f];
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
