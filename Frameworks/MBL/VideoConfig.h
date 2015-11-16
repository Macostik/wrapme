//
//  VideoConfig.h
//  mbl
//
//  Created by Anton Korovin on 28/08/15.
//  Copyright (c) 2015 Softvelum LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIGeometry.h>
#include <VideoToolbox/VideoToolbox.h>

@interface VideoConfig : NSObject

@property NSString* cameraID;
@property CGSize videoSize;
@property float  fps;
@property float  keyFrameInterval;
@property int    bitrate;
@property NSString* profileLevel;

+(NSArray*)getSupportedProfiles;

@end
