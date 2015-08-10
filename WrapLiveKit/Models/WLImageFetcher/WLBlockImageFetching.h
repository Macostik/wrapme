//
//  WLBlockImageFetching.h
//  moji
//
//  Created by Ravenpod on 7/9/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLBlockImageFetching : NSObject

+ (instancetype)fetchingWithUrl:(NSString*)url;

- (instancetype)initWithUrl:(NSString*)url;

- (id)enqueue:(WLImageBlock)success failure:(WLFailureBlock)failure;

@end
