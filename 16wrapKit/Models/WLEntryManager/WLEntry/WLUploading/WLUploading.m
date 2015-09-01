//
//  WLUploading.m
//  moji
//
//  Created by Ravenpod on 13.06.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLUploading.h"
#import "WLCandy.h"

@implementation WLUploading

@dynamic contribution;

@dynamic type;

@synthesize data = _data;

- (WLUploadingData *)data {
    if (!_data) {
        _data = [[WLUploadingData alloc] init];
        _data.uploading = self;
    }
    return _data;
}

@end
