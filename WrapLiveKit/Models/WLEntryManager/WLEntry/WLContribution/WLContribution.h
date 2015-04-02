//
//  WLContribution.h
//  WrapLive
//
//  Created by Sergey Maximenko on 13.06.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "WLEntry.h"

@class WLUser;
@class WLUploading;

@interface WLContribution : WLEntry

@property (nonatomic, retain) WLUser *contributor;

@property (nonatomic, retain) WLUploading *uploading;

@property (nonatomic, retain) NSString * uploadIdentifier;

@end
