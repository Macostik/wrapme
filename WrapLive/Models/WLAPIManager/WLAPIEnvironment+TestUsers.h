//
//  WLAPIEnvironment+TestUsers.h
//  WrapLive
//
//  Created by Yura Granchenko on 12/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAPIEnvironment.h"

@interface WLAPIEnvironment (TestUsers)

- (void)testUsers:(void (^)(NSArray* testUsers))completion;

@end
