//
//  WLUploading+Extended.h
//  meWrap
//
//  Created by Ravenpod on 6/13/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCommonEnums.h"

@interface Uploading (Extended)

+ (instancetype)uploading:(Contribution *)contribution;

+ (instancetype)uploading:(Contribution *)contribution type:(WLEvent)type;

- (void)upload:(WLObjectBlock)success failure:(WLFailureBlock)failure;

@end
