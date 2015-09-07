//
//  WLUploading+Extended.h
//  meWrap
//
//  Created by Ravenpod on 6/13/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLUploading.h"
#import "WLCommonEnums.h"

@interface WLUploading (Extended)

+ (instancetype)uploading:(WLContribution*)contribution;

+ (instancetype)uploading:(WLContribution*)contribution type:(WLEvent)type;

- (id)upload:(WLObjectBlock)success failure:(WLFailureBlock)failure;

@end
