//
//  WLUploading.h
//  WrapLive
//
//  Created by Sergey Maximenko on 13.06.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "WLEntry.h"
#import <AFNetworking/AFHTTPRequestOperation.h>

@class WLContribution;

@interface WLUploading : WLEntry

@property (nonatomic, retain) WLContribution *contribution;

@property (weak, nonatomic) AFHTTPRequestOperation* operation;

@end
