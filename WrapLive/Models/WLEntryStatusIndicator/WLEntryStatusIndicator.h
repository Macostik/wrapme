//
//  WLEntryStatusIndicator.h
//  WrapLive
//
//  Created by Yura Granchenko on 22/04/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLIconView.h"

inline static NSString* iconNameByStatus(WLContributionStatus status) {
    switch (status) {
        case WLContributionStatusReady:
            return @"clock";
            break;
        case WLContributionStatusInProgress:
            return @"check";
            break;
        case WLContributionStatusUploaded:
            return @"double-check";
            break;
        default:
             return @"";
            break;
    }
}

@interface WLEntryStatusIndicator : WLIconView

- (void)updateStatusIndicator:(WLContribution *)contribution;

@end
