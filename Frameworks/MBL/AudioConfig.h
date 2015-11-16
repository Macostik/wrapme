//
//  AudioConfig.h
//  mbl
//
//  Created by Anton Korovin on 28/08/15.
//  Copyright (c) 2015 Softvelum LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AudioUnit;

@interface AudioConfig : NSObject

@property float sampleRate;
@property int channelCount;
@property int bitrate;
@property AudioFormatID profile;

+(NSArray*)getSupportedSampleRates;
+(int)getBitrateWithSampleRate:(int)sampleRate channelCount:(int)channelCount;
+(NSArray*)getSupportedAACProfiles;

@end
