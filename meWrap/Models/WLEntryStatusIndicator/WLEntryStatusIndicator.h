//
//  WLEntryStatusIndicator.h
//  meWrap
//
//  Created by Yura Granchenko on 22/04/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLLabel.h"
#import "WLEntry+Extended.h"

static NSInteger WLIndicatorWidth = 16.0;

inline static NSString* iconNameByContribution(WLContribution *contribution) {
    if (![(id)contribution.container uploaded]) {
        return @"D";
    }
    switch ([contribution statusOfAnyUploadingType]) {
        case WLContributionStatusReady:
            return @"D";
            break;
        case WLContributionStatusInProgress:
            return @"E";
            break;
        case WLContributionStatusFinished:
            return @"F";
            break;
        default:
            return @"D";
            break;
    }
}


@interface WLEntryStatusIndicator : WLLabel

- (void)updateStatusIndicator:(WLContribution *)contribution;

@end



