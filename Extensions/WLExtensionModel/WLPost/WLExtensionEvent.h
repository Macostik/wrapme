//
//  WLExtensionEvent.h
//  WrapLive
//
//  Created by Yura Granchenko on 11/28/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLExtensionComment.h"
#import "DefinedBlocks.h"

static NSString *WLExtensionEventTypeComment = @"comment";
static NSString *WLExtensionEventTypeCandy = @"candy";

@interface WLExtensionEvent : WLArchivingObject

@property (strong, nonatomic) NSURL *image;
@property (strong, nonatomic) NSString *wrapName;
@property (strong, nonatomic) NSString *event;
@property (strong, nonatomic) NSString *contributor;
@property (strong, nonatomic) NSString *identifier;
@property (strong, nonatomic) NSDate *lastTouch;
@property (strong, nonatomic) NSString* type;

@property (strong, nonatomic) WLExtensionComment *comment;

+ (id)postWithAttributes:(NSDictionary *)attributes;

+ (NSURLSessionDataTask *)posts:(WLArrayBlock)success failure:(WLFailureBlock)failure;

@end
