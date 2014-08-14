//
//  WLUploadAPIRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLUploadAPIRequest.h"

@implementation WLUploadAPIRequest

+ (NSString *)defaultMethod {
    return @"POST";
}

- (NSMutableURLRequest *)request:(NSMutableDictionary *)parameters url:(NSString *)url {
    NSString* filePath = self.filePath;
    void (^constructing) (id<AFMultipartFormData> formData) = ^(id<AFMultipartFormData> formData) {
        if (filePath && [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            [formData appendPartWithFileURL:[NSURL fileURLWithPath:filePath]
                                       name:@"qqfile"
                                   fileName:[filePath lastPathComponent]
                                   mimeType:@"image/jpeg" error:NULL];
        }
    };
    return [self.manager.requestSerializer multipartFormRequestWithMethod:self.method
                                                                URLString:url
                                                               parameters:parameters
                                                constructingBodyWithBlock:constructing
                                                                    error:NULL];
}

@end
