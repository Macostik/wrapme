//
//  NSDate+PNTimetoken.h
//  meWrap
//
//  Created by Ravenpod on 7/7/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (PNTimetoken)

+ (instancetype)dateWithTimetoken:(NSNumber*)timetoken;

- (NSNumber*)timetoken;

@end
