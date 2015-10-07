//
//  WLUploading.h
//  meWrap
//
//  Created by Ravenpod on 13.06.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "WLEntry.h"

@class WLContribution;

@interface WLUploading : WLEntry

@property (nonatomic) int16_t type;

@property (nonatomic, retain) WLContribution *contribution;

@property (nonatomic) BOOL inProgress;

@end
