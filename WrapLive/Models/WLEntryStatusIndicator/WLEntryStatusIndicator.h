//
//  WLEntryStatusIndicator.h
//  WrapLive
//
//  Created by Yura Granchenko on 22/04/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLIconView.h"
#import "WLEntry+Extended.h"

inline static NSString* iconNameByContribution(WLContribution *contribution) {
    if (![(id)contribution.containingEntry uploaded]) {
        return @"clock";
    }
    
    switch (contribution.status) {
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



