//
//  WLErrorRow.m
//  WrapLive
//
//  Created by Sergey Maximenko on 3/30/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWKErrorRow.h"

@implementation WLWKErrorRow

- (void)setError:(NSError *)error {
    [self.errorDescriptionLabel setText:error.localizedDescription];
}

@end
