//
//  WLEntityRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 9/12/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEntityRequest.h"
#import "WLEntryNotifier.h"

@implementation WLEntityRequest

+ (instancetype)request:(WLEntry *)entry {
    WLEntityRequest* request = [WLEntityRequest request];
    request.entry = entry;
    return request;
}

- (NSString *)path {
    return [NSString stringWithFormat:@"entities/%@", self.entry.identifier];
}

- (id)objectInResponse:(WLAPIResponse *)response {
    WLEntry *entry = self.entry;
    return entry.valid ? [entry update:[response.data objectForPossibleKeys:WLWrapKey,WLCandyKey,WLMessageKey,WLCommentKey, nil]] : nil;
}

- (void)handleFailure:(NSError *)error {
    if (error.isContentUnavaliable) {
        WLContribution* contribution = (id)self.entry;
        if ([contribution isKindOfClass:[WLContribution class]] && contribution.uploaded) {
            [contribution remove];
            self.entry = nil;
        }
    }
    [super handleFailure:error];
}

@end