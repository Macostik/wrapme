//
//  WLPost.h
//  WrapLive
//
//  Created by Yura Granchenko on 11/28/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLComments.h"

@interface WLPost : WLArchivingObject

@property (strong, nonatomic) NSData *image;
@property (strong, nonatomic) NSString *wrapName;
@property (strong, nonatomic) NSString *event;
@property (strong, nonatomic) NSDate *time;
@property (strong, nonatomic) NSString *contributor;
@property (strong, nonatomic) NSString *identifier;
@property (strong, nonatomic) NSString *lastTouch;

@property (strong, nonatomic) WLComments *comment;

+ (id)initWithAttributes:(NSDictionary *)attributes;
+ (NSURLSessionDataTask *)globalTimelinePostsWithBlock:(void (^)(NSArray *posts, NSError *error))block;

@end

@interface NSDate (WLPost)

- (NSString *)timeAgoStringAtAMPM;

@end
