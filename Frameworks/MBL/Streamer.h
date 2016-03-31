//
//  Streamer.h
//  mbl
//
//  Created by Anton Korovin on 25/08/15.
//  Copyright (c) 2015 Softvelum LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "VideoConfig.h"
#import "AudioConfig.h"

typedef NS_ENUM(int, ConnectionMode) {
    kConnectionModeVideoAudio = 0,
    kConnectionModeVideoOnly = 1,
    kConnectionModeAudioOnly = 2
};


typedef NS_ENUM(int, ConnectionState) {
    kConnectionStateInitialized,
    kConnectionStateConnected,
    kConnectionStateSetup,
    kConnectionStateRecord,
    kConnectionStateDisconnected
};

typedef NS_ENUM(int, ConnectionStatus) {
    kConnectionStatusSuccess,
    kConnectionStatusConnectionFail,
    kConnectionStatusAuthFail,
    kConnectionStatusUnknownFail
};

typedef NS_ENUM(int, CaptureState) {
    kCaptureStateInitial,
    kCaptureStateStarted,
    kCaptureStateStoped,
    kCaptureStateFailed
};

@protocol StreamerListener
-(void)connectionStateDidChangeId:(int)connectionID State:(ConnectionState)state Status:(ConnectionStatus)status;
-(void)videoCaptureStateDidChange:(CaptureState)state;
-(void)audioCaptureStateDidChange:(CaptureState)state;
@end


@interface Camera : NSObject {
    
    
}
@property NSString* cameraID;
@property NSArray* resolutions;
@end


@interface Streamer : NSObject

+(id)instance;

// video capture
-(AVCaptureVideoPreviewLayer*)startVideoCaptureWithCamera:(NSString*)cameraID orientation:(AVCaptureVideoOrientation)orientation config:(VideoConfig*)config listener:(id)listener;
-(void)stopVideoCapture;

// audio capture
-(void)startAudioCaptureWithConfig:(AudioConfig*)config  listener:(id)listener;
-(void)stopAudioCapture;

// rtsp connection
-(int)createConnectionWithListener:(id)listener Uri:(NSString*)uri mode:(int)mode;
-(uint64_t)getBytesSent:(int)connectionID;
-(uint64_t)getBytesRecv:(int)connectionID;
-(void)releaseConnectionId:(int)id;
-(bool)changeCamera;

// fps
-(double)getFps;
@end
