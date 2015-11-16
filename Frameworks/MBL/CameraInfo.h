//
//  CameraInfo.h
//  mbl
//
//  Created by Anton Korovin on 28/08/15.
//  Copyright (c) 2015 Softvelum LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CameraInfo : NSObject
@property (readonly) NSString* cameraID;
@property (readonly) NSString* name;
@property (readonly) int position;
@property (readonly) NSArray*  videoSizes;

+(NSArray*)getCameraList;
+(id)getCameraInfoByID:(NSString*)cameraID;
@end
