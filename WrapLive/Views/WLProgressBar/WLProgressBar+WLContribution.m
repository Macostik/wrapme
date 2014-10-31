//
//  WLProgressBar+WLContribution.m
//  WrapLive
//
//  Created by Sergey Maximenko on 10/31/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLProgressBar+WLContribution.h"
#import <AFNetworking/AFURLConnectionOperation.h>
#import "WLInternetConnectionBroadcaster.h"
#import "WLContribution+Extended.h"
#import "WLUploading+Extended.h"
#import "NSObject+AssociatedObjects.h"

@interface AFURLConnectionOperation (WLProgressBar)

@property (nonatomic) float progress;

- (void)setProgressBlock:(void (^)(float progress))block;

@end

@implementation AFURLConnectionOperation (WLProgressBar)

- (void)setProgress:(float)progress {
    [self setAssociatedObject:@(progress) forKey:"WLProgressBar_progress"];
}

- (float)progress {
    return [[self associatedObjectForKey:"WLProgressBar_progress"] floatValue];
}

- (void)setProgressBlock:(void (^)(float progress))block {
    __weak typeof(self)weakSelf = self;
    [self setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        float progress = 0.5f * ((float)totalBytesWritten/(float)totalBytesExpectedToWrite);
        weakSelf.progress = progress;
        if (block) {
            block(progress);
        }
    }];
    [self setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        float progress = 0.5f + 0.5f * ((float)totalBytesRead/(float)totalBytesExpectedToRead);
        weakSelf.progress =  progress;
        if (block) {
            block(progress);
        }
    }];
}

@end

@implementation WLProgressBar (WLContribution)

- (void)setContribution:(WLContribution *)contribution {
    if (contribution.uploading) {
        if (contribution.uploading.operation) {
            [self setOperation:contribution.uploading.operation];
        } else {
            self.progress = WLDefaultProgress;
        }
    } else {
        self.progress = 0.0f;
    }
}

- (void)setOperation:(AFURLConnectionOperation *)operation {
    __weak typeof(self)weakSelf = self;
    if ([WLInternetConnectionBroadcaster broadcaster].reachable) {
        self.progress = WLDefaultProgress + (1.0f - WLDefaultProgress) * operation.progress;
        [operation setProgressBlock:^(float progress) {
            [weakSelf setProgress:WLDefaultProgress + (1.0f - WLDefaultProgress) * progress animated:YES];
        }];
    } else {
        self.progress = WLDefaultProgress;
    }
}

@end
