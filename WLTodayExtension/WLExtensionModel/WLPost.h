//
//  WLPost.h
//  WrapLive
//
//  Created by Yura Granchenko on 11/28/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLPost : NSObject

@property (strong, nonatomic) NSData *image;
@property (strong, nonatomic) NSString *wrapName;
@property (strong, nonatomic) NSString *event;
@property (strong, nonatomic) NSDate *time;

+ (id)initWithAttributes:(NSDictionary *)attributes;
- (NSString *)timeAgoString:(NSDate *)date;

@end
