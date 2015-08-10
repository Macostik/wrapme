//
//  WLUploading.h
//  moji
//
//  Created by Ravenpod on 13.06.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "WLEntry.h"
#import "WLUploadingData.h"

@class WLContribution;

@interface WLUploading : WLEntry

@property (nonatomic) int16_t type;

@property (nonatomic, retain) WLContribution *contribution;

@property (strong, nonatomic) WLUploadingData* data;

@end
