//
//  WLContribution.h
//  meWrap
//
//  Created by Ravenpod on 13.06.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "WLEntry.h"

@class WLUser;
@class WLUploading;

@interface WLContribution : WLEntry

@property (nonatomic, retain) WLUser *contributor;

@property (nonatomic, retain) WLUploading *uploading;

@property (nonatomic, retain) WLUser *editor;

@property (nonatomic, retain) NSDate *editedAt;

@end
