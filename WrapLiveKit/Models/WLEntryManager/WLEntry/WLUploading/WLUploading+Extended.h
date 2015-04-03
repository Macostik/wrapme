//
//  WLUploading+Extended.h
//  WrapLive
//
//  Created by Sergey Maximenko on 6/13/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLUploading.h"

@interface WLUploading (Extended)

+ (instancetype)uploading:(WLContribution*)contribution;

- (id)upload:(WLObjectBlock)success failure:(WLFailureBlock)failure;

@end
