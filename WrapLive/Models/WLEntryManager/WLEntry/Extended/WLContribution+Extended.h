//
//  WLContribution.h
//  CoreData1
//
//  Created by Sergey Maximenko on 13.06.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLContribution.h"

@interface WLContribution (Extended)

@property (readonly, nonatomic) BOOL uploaded;

+ (instancetype)contribution;

+ (NSNumber*)uploadingOrder;

- (BOOL)shouldStartUploadingAutomatically;

- (BOOL)canBeUploaded;

@end
