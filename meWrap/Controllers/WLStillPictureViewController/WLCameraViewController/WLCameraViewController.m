//
//  WLCameraViewController.m
//  meWrap
//
//  Created by Ravenpod on 10.04.13.
//
//

#import "WLCameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import "UIImage+Resize.h"
#import "WLFlashModeControl.h"
#import "WLCameraAdjustmentView.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "WLDeviceManager.h"
#import "WLToast.h"
#import "WLWrapView.h"
#import "WLQuickAssetsViewController.h"
#import "WLProgressBar.h"
@import AVKit;

@interface WLCameraView : UIView

@property(nonatomic,readonly,retain) AVCaptureVideoPreviewLayer *layer;

@end

@implementation WLCameraView

@dynamic layer;

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.layer.videoGravity = AVLayerVideoGravityResizeAspect;
}

@end

@interface WLCameraViewController () <WLDeviceOrientationBroadcastReceiver, UIGestureRecognizerDelegate, AVCaptureFileOutputRecordingDelegate>

#pragma mark - AVCaptureSession interface

@property (strong, nonatomic) AVCaptureMovieFileOutput *movieFileOutput;

@property (strong, nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureSession* session;
@property (nonatomic, weak) AVCaptureConnection* stillImageOutputConnection;
@property (nonatomic, weak) AVCaptureConnection* movieFileOutputConnection;
@property (nonatomic) AVCaptureFlashMode flashMode;
@property (nonatomic) CGFloat zoomScale;

#pragma mark - UIKit interface

@property (weak, nonatomic) IBOutlet UIView *cropAreaView;
@property (weak, nonatomic) IBOutlet UILabel *unauthorizedStatusView;
@property (weak, nonatomic) IBOutlet WLCameraView *cameraView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet WLFlashModeControl *flashModeControl;
@property (weak, nonatomic) IBOutlet UIButton *rotateButton;
@property (weak, nonatomic) IBOutlet UILabel *zoomLabel;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@property (weak, nonatomic) WLQuickAssetsViewController* assetsViewController;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *assetsBottomConstraint;
@property (weak, nonatomic) IBOutlet UILabel *assetsArrow;
@property (weak, nonatomic) IBOutlet UIView *assetsView;

@property (strong, nonatomic) dispatch_queue_t sessionQueue;

@property (weak, nonatomic) NSTimer *videoRecordingTimer;
@property (weak, nonatomic) NSTimer *startVideoRecordingTimer;


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cameraViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewHeightConstraint;
@property (weak, nonatomic) IBOutlet WLProgressBar *videoRecordingProgressBar;
@property (weak, nonatomic) IBOutlet UIView *videoRecordingView;
@property (weak, nonatomic) IBOutlet UILabel *videoRecordingTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *cancelVideoRecordingLabel;
@property (weak, nonatomic) IBOutlet UIView *videoRecordingIndicator;

@property (weak, nonatomic) AVCaptureDeviceInput *audioInput;

@property (nonatomic) BOOL videoRecordingCancelled;

@property (nonatomic) NSTimeInterval videoRecordingTimeLeft;

@property (strong, nonatomic) NSString *videoFilePath;

@end

@implementation WLCameraViewController

@synthesize wrapView = _wrapView;

@dynamic delegate;

- (void)dealloc {
    [[WLDeviceManager manager] endUsingAccelerometer];
    if (self.videoFilePath) {
        [[NSFileManager defaultManager] removeItemAtPath:self.videoFilePath error:nil];
    }
}

#pragma mark - View controller lifecycle

- (void)viewDidLoad {
    
    if (self.bottomViewHeightConstraint) {
        CGRect frame = self.preferredViewFrame;
        CGFloat bottomViewHeight = MAX(130, frame.size.height - frame.size.width / 0.75);
        self.bottomViewHeightConstraint.constant = bottomViewHeight;
        self.cameraViewBottomConstraint.constant = bottomViewHeight;
    }
    
	[super viewDidLoad];
    
    self.sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
	
    [[WLDeviceManager manager] addReceiver:self];
    [[WLDeviceManager manager] beginUsingAccelerometer];
    
	if (self.presentingViewController) {
		self.view.frame = self.presentingViewController.view.bounds;
        [self.view layoutIfNeeded];
	}
    
    self.cropAreaView.layer.borderWidth = 1;
    self.cropAreaView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.25].CGColor;
    
    __weak typeof(self)weakSelf = self;
    
    [self authorize:^{
        AVCaptureDevicePosition defaultPosition = AVCaptureDevicePositionBack;
        AVCaptureFlashMode flashMode = AVCaptureFlashModeOff;
        if (weakSelf.mode == WLStillPictureModeDefault) {
            NSNumber *savedDefaultPosition = WLSession.cameraDefaultPosition;
            if (savedDefaultPosition) defaultPosition = [savedDefaultPosition integerValue];
            NSNumber *savedFlashMode = WLSession.cameraDefaultFlashMode;
            if (savedFlashMode) flashMode = [savedFlashMode integerValue];
        } else {
            defaultPosition = AVCaptureDevicePositionFront;
        }
        weakSelf.position = defaultPosition;
        weakSelf.flashMode = weakSelf.flashModeControl.mode = flashMode;
        weakSelf.cameraView.layer.session = weakSelf.session;
        [weakSelf start];
        
        if (weakSelf.mode == WLStillPictureModeDefault) {
            UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:weakSelf action:@selector(startVideoRecording:)];
            longPressGestureRecognizer.delegate = self;
            [weakSelf.takePhotoButton addGestureRecognizer:longPressGestureRecognizer];
        }
    } failure:^(NSError *error) {
        weakSelf.unauthorizedStatusView.hidden = NO;
        weakSelf.takePhotoButton.active = NO;
    }];
    
    for (WLQuickAssetsViewController *assetsViewController in self.childViewControllers) {
        if ([assetsViewController isKindOfClass:[WLQuickAssetsViewController class]]) {
            self.assetsViewController = assetsViewController;
            self.assetsViewController.delegate = self.delegate;
            self.assetsViewController.mode = self.mode;
            break;
        }
    }
}

- (void)authorize:(WLBlock)success failure:(WLFailureBlock)failure {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusAuthorized) {
        if (success) success();
    } else if (status == AVAuthorizationStatusDenied || status == AVAuthorizationStatusRestricted) {
        if (failure) failure(nil);
    } else {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            run_in_main_queue(^{
                if (granted) {
                    if (success) success();
                } else {
                    if (failure) failure(nil);
                }
            });
        }];
    }
}

#pragma mark - User Actions

- (IBAction)cancel:(id)sender {
	if (self.delegate) {
		[self.delegate cameraViewControllerDidCancel:self];
	} else if (self.presentingViewController) {
		[self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
	}
}

- (IBAction)shot:(UIButton*)sender {
    if ([self.delegate respondsToSelector:@selector(cameraViewControllerCaptureMedia:)]) {
        if ([self.delegate cameraViewControllerCaptureMedia:self] == NO) {
            return;
        }
    }
    
    [self setAssetsViewControllerHidden:YES animated:YES];
	__weak typeof(self)weakSelf = self;
	self.view.userInteractionEnabled = NO;
	sender.active = NO;
    
    [UIView animateWithDuration:0.1 animations:^{
        weakSelf.cameraView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            weakSelf.cameraView.alpha = 1.0f;
        }];
    }];
    
    [self captureImage:^(UIImage *image) {
        [weakSelf finishWithImage:image];
        weakSelf.view.userInteractionEnabled = YES;
        run_after(0.5f, ^{
            sender.active = YES;
        });
    } failure:^(NSError *error) {
        sender.active = YES;
        weakSelf.view.userInteractionEnabled = YES;
        [error show];
    }];
}

- (IBAction)finish:(id)sender {
    if ([self.delegate respondsToSelector:@selector(cameraViewControllerDidFinish:)]) {
        [self.delegate cameraViewControllerDidFinish:self];
    }
}

- (IBAction)panning:(UIPanGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [sender translationInView:sender.view];
        self.assetsBottomConstraint.constant = Smoothstep(-self.assetsViewController.view.height, 0, self.assetsBottomConstraint.constant - translation.y / 2);
        self.assetsArrow.layer.transform = CATransform3DMakeRotation(M_PI * self.assetsBottomConstraint.constant / self.assetsViewController.view.height, 1, 0, 0);
        [self.view layoutIfNeeded];
        [sender setTranslation:CGPointZero inView:sender.view];
    } else if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled) {
        CGFloat velocity = [sender velocityInView:sender.view].y;
        if (ABS(velocity) > 500) {
            [self setAssetsViewControllerHidden:velocity > 0 animated:YES];
        } else {
            [self setAssetsViewControllerHidden:ABS(self.assetsBottomConstraint.constant) > self.assetsViewController.view.height/2 animated:YES];
        }
    }
}

- (IBAction)toggleQuickAssets:(id)sender {
    [self setAssetsViewControllerHidden:self.assetsBottomConstraint.constant == 0 animated:YES];
}

- (void)setAssetsViewControllerHidden:(BOOL)hidden animated:(BOOL)animated {
    if (hidden) {
        self.assetsBottomConstraint.constant = -self.assetsViewController.view.height;
    } else {
        self.assetsBottomConstraint.constant = 0;
    }
    [UIView animateWithDuration:animated ? 0.3 : 0 delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseIn animations:^{
        if (hidden) {
            self.assetsArrow.layer.transform = CATransform3DMakeRotation(M_PI, 1, 0, 0);
        } else {
            self.assetsArrow.layer.transform = CATransform3DIdentity;
        }
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
    }];
}

- (void)finishWithImage:(UIImage*)image {
    [self.delegate cameraViewController:self didFinishWithImage:image saveToAlbum:YES];
}

- (IBAction)flashModeChanged:(WLFlashModeControl *)sender {
	self.flashMode = sender.mode;
	if (self.flashMode != sender.mode) {
        run_after_asap(^{
            sender.mode = self.flashMode;
        });
	}
    if (self.mode == WLStillPictureModeDefault) {
        WLSession.cameraDefaultFlashMode = @(self.flashMode);
    }
}

- (IBAction)rotateCamera:(id)sender {
	if (self.position == AVCaptureDevicePositionBack) {
		self.position = AVCaptureDevicePositionFront;
	} else {
		self.position = AVCaptureDevicePositionBack;
	}
	self.flashMode = self.flashModeControl.mode;
    self.zoomScale = 1;
    if (self.mode == WLStillPictureModeDefault) {
        if (self.position != AVCaptureDevicePositionUnspecified)
            WLSession.cameraDefaultPosition = @(self.position);
    }
}

- (IBAction)zooming:(UIPinchGestureRecognizer*)sender {
	if (sender.state == UIGestureRecognizerStateChanged) {
		self.zoomScale = self.zoomScale * sender.scale;
		sender.scale = 1;
	}
}

- (IBAction)focusing:(UITapGestureRecognizer*)sender {
	if(![self.session isRunning]) {
        return;
    }
	
	for (UIView* subview in self.cameraView.subviews) {
		if ([subview isKindOfClass:[WLCameraAdjustmentView class]]) {
			[subview removeFromSuperview];
		}
	}
	
	CGPoint point = [sender locationInView:self.cameraView];
    [self autoFocusAndExposureAtPoint:point];
	WLCameraAdjustmentView *focusView = [[WLCameraAdjustmentView alloc] initWithFrame:CGRectMake(0, 0, 67, 67)];
	focusView.center = point;
	focusView.userInteractionEnabled = NO;
	[self.cameraView addSubview:focusView];
	[UIView animateWithDuration:0.33f delay:1.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		focusView.alpha = 0.0f;
	} completion:^(BOOL finished) {
		[focusView removeFromSuperview];
	}];
}

- (IBAction)getSamplePhoto:(id)sender {
    self.takePhotoButton.active = NO;
    __weak typeof(self)weakSelf = self;
    run_getting_object(^id{
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        CGSize size = CGSizeMake(width, width / 0.75);
        NSString* url = [NSString stringWithFormat:@"http://placeimg.com/%d/%d/any", (int)size.width, (int)size.height];
        return [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[url URL]]];
    }, ^ (UIImage* image) {
        if (image) {
            [weakSelf.delegate cameraViewController:weakSelf didFinishWithImage:image saveToAlbum:NO];
        }
        weakSelf.takePhotoButton.active = YES;
    });
}

- (void)startVideoRecording:(UILongPressGestureRecognizer*)sender {
    if ([self.delegate respondsToSelector:@selector(cameraViewControllerCaptureMedia:)]) {
        if ([self.delegate cameraViewControllerCaptureMedia:self] == NO) {
            return;
        }
    }
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            [self updateVideoRecordingViews:YES];
            [self prepareSessionForVideoRecording:^{
                self.startVideoRecordingTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                                                 target:self
                                                                               selector:@selector(startVideoRecording)
                                                                               userInfo:nil
                                                                                repeats:NO];
            }];
        } break;
        case UIGestureRecognizerStateEnded: {
            CGPoint location = [sender locationInView:self.videoRecordingView];
            if (CGRectContainsPoint(self.cancelVideoRecordingLabel.frame, location)) {
                [self cancelVideoRecording];
            } else {
                [self stopVideoRecording];
            }
        } break;
        default:
            break;
    }
}

- (void)updateVideoRecordingViews:(BOOL)recording {
    self.bottomView.hidden = recording;
    self.assetsView.hidden = recording;
    self.wrapView.hidden = recording;
    self.rotateButton.hidden = recording;
    self.cropAreaView.hidden = recording;
    self.flashModeControl.alpha = recording ? 0.0f : 1.0f;
}

- (void)prepareSessionForVideoRecording:(WLBlock)preparingCompletion {
    __weak typeof(self)weakSelf = self;
    if (![self.session.outputs containsObject:self.movieFileOutput]) {
        [self blurCamera:^(WLBlock completion) {
            [self configureSession:^(AVCaptureSession *session) {
                session.sessionPreset = AVCaptureSessionPresetMedium;
                AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio] error:nil];
                if ([session canAddInput:input]) {
                    [session addInput:input];
                }
                weakSelf.audioInput = input;
                [session removeOutput:weakSelf.stillImageOutput];
                if ([session canAddOutput:weakSelf.movieFileOutput]) {
                    [session addOutput:weakSelf.movieFileOutput];
                }
            } completion:^{
                AVCaptureTorchMode torchMode = (AVCaptureTorchMode)weakSelf.flashMode;
                [weakSelf configureCurrentDevice:^(AVCaptureDevice *device) {
                    device.videoZoomFactor = _zoomScale;
                    if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                        [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
                    }
                    if (device.hasTorch && device.torchAvailable && [device isTorchModeSupported:torchMode]) {
                        device.torchMode = torchMode;
                    }
                }];
                [weakSelf applyDeviceOrientation:[WLDeviceManager manager].orientation forConnection:weakSelf.movieFileOutputConnection];
                completion();
                preparingCompletion();
            }];
        }];
    }
}

- (void)blurCamera:(void (^)(WLBlock completion))handler {
    UIView *snapshot = [self.cameraView.superview snapshotViewAfterScreenUpdates:YES];
    snapshot.frame = self.cameraView.superview.bounds;
    snapshot.alpha = 0;
    [self.cameraView.superview insertSubview:snapshot aboveSubview:self.cameraView];
    
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    effectView.frame = snapshot.bounds;
    [snapshot addSubview:effectView];
    [UIView animateWithDuration:0.2 animations:^{
        snapshot.alpha = 1;
    }];
    if (handler) handler(^ {
        [UIView animateWithDuration:0.2 animations:^{
            snapshot.alpha = 0;
        } completion:^(BOOL finished) {
            [snapshot removeFromSuperview];
        }];
    });
}

- (void)prepareSessionForPhotoTaking {
    __weak typeof(self)weakSelf = self;
    if (![self.session.outputs containsObject:self.stillImageOutput]) {
        self.takePhotoButton.userInteractionEnabled = NO;
        [self blurCamera:^(WLBlock completion) {
            [self configureSession:^(AVCaptureSession *session) {
                session.sessionPreset = AVCaptureSessionPresetPhoto;
                [session removeInput:weakSelf.audioInput];
                [session removeOutput:weakSelf.movieFileOutput];
                if ([session canAddOutput:weakSelf.stillImageOutput]) {
                    [session addOutput:weakSelf.stillImageOutput];
                }
            } completion:^{
                [weakSelf configureCurrentDevice:^(AVCaptureDevice *device) {
                    device.videoZoomFactor = _zoomScale;
                    if ([device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
                        [device setFocusMode:AVCaptureFocusModeAutoFocus];
                    }
                    if ([device isTorchModeSupported:AVCaptureTorchModeOff]) {
                        device.torchMode = AVCaptureTorchModeOff;
                    }
                }];
                [weakSelf applyDeviceOrientation:[WLDeviceManager manager].orientation forConnection:weakSelf.stillImageOutputConnection];
                weakSelf.takePhotoButton.userInteractionEnabled = YES;
                completion();
            }];
        }];
    }
}

- (void)startVideoRecording {
    self.videoRecordingCancelled = NO;
    NSString *videosDirectoryPath = @"Documents/Videos";
 	NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:videosDirectoryPath withIntermediateDirectories:YES attributes:nil error:&error];
    NSString *path = [NSString stringWithFormat:@"%@/capturedVideo.mov", videosDirectoryPath];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    self.videoFilePath = path;
    if (!error && path.nonempty) {
        if ([self.session.outputs containsObject:self.movieFileOutput]) {
            [self.movieFileOutput startRecordingToOutputFileURL:[path fileURL] recordingDelegate:self];
        }
    }
}

- (void)stopVideoRecording {
    if (self.movieFileOutput.recording) {
        [self.movieFileOutput stopRecording];
    } else {
        if (self.bottomView.hidden) {
            [self prepareSessionForPhotoTaking];
            [self updateVideoRecordingViews:NO];
        }
        [self.startVideoRecordingTimer invalidate];
        self.startVideoRecordingTimer = nil;
    }
}

- (void)cancelVideoRecording {
    self.videoRecordingCancelled = YES;
    [self stopVideoRecording];
}

#pragma mark - AVCaptureSession

- (AVCaptureDevice*)deviceWithPosition:(AVCaptureDevicePosition)position {
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] select:^BOOL(AVCaptureDevice *device) {
        return [device position] == position;
    }];
}

- (AVCaptureDeviceInput*)inputWithPosition:(AVCaptureDevicePosition)position {
    AVCaptureDevice *device = [self deviceWithPosition:position];
    if (device) {
        [device lockForConfiguration:nil];
        if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
            device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        [device unlockForConfiguration];
        return [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    }
    return nil;
}

- (void)setVideoInput:(AVCaptureDeviceInput *)videoInput {
	AVCaptureSession* session = self.session;
	[session beginConfiguration];
	if (_videoInput) {
		[session removeInput:_videoInput];
	}
	if ([session canAddInput:videoInput]) {
        _videoInput = videoInput;
		[session addInput:videoInput];
	}
	[session commitConfiguration];
	self.flashModeControl.hidden = !videoInput.device.hasFlash;
	[self applyDeviceOrientation:[WLDeviceManager manager].orientation];
}

- (AVCaptureSession *)session {
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
        if ([_session canSetSessionPreset:AVCaptureSessionPresetPhoto]) {
            _session.sessionPreset = AVCaptureSessionPresetPhoto;
        } else {
            _session.sessionPreset = AVCaptureSessionPresetMedium;
        }
        [_session addOutput:self.stillImageOutput];
    }
    return _session;
}

- (AVCaptureMovieFileOutput *)movieFileOutput {
    if (!_movieFileOutput) {
        _movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
        CMTime maxDuration = CMTimeMakeWithSeconds(maxVideoRecordedDuration, NSEC_PER_SEC);
        _movieFileOutput.maxRecordedDuration = maxDuration;
        [_movieFileOutput setMovieFragmentInterval:kCMTimeInvalid];
    }
    return _movieFileOutput;
}

- (AVCaptureStillImageOutput *)stillImageOutput {
	if (!_stillImageOutput) {
		_stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
		[_stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
	}
	return _stillImageOutput;
}

- (void)start {
    dispatch_async(self.sessionQueue, ^{
        if (!self.session.isRunning) {
            [self.session startRunning];
        }
    });
}

- (void)stop {
    dispatch_async(self.sessionQueue, ^{
        if (self.session.isRunning) {
            [self.session stopRunning];
        }
    });
}

- (AVCaptureConnection*)stillImageOutputConnection {
    return [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
}

- (AVCaptureConnection *)movieFileOutputConnection {
    return [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
}

- (void)captureImage:(void (^)(UIImage*image))result failure:(WLFailureBlock)failure {
#if TARGET_IPHONE_SIMULATOR
	run_getting_object(^id{
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        CGSize size = CGSizeMake(width, width / 0.75);
		NSString* url = url = [NSString stringWithFormat:@"http://placeimg.com/%d/%d/any", (int)size.width, (int)size.height];
		return [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[url URL]]];
	}, ^ (UIImage* image) {
        if (image) {
            if (result) result(image);
        } else {
            if (failure) failure(nil);
        }
	});
	return;
#endif
    
	void (^handler) (CMSampleBufferRef, NSError *) = ^(CMSampleBufferRef buffer, NSError *error) {
        if (!error) {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:buffer];
            UIImage* image = [[UIImage alloc] initWithData:imageData];
            if (result) result(image);
        } else {
            if (failure) failure(error);
        }
	};
    
    AVCaptureStillImageOutput *output = self.stillImageOutput;
    AVCaptureConnection *connection = [output connectionWithMediaType:AVMediaTypeVideo];
    if (connection && [self.session.outputs containsObject:output]) {
        connection.videoMirrored = (self.position == AVCaptureDevicePositionFront);
        [output captureStillImageAsynchronouslyFromConnection:connection completionHandler:handler];
    } else {
        if (failure) failure(nil);
    }
}

- (AVCaptureDevicePosition)position {
	return self.videoInput.device.position;
}

- (void)setPosition:(AVCaptureDevicePosition)position {
    [self setPosition:position animated:NO];
}

- (void)setPosition:(AVCaptureDevicePosition)position animated:(BOOL)animated {
	self.videoInput = [self inputWithPosition:position];
}

- (void)configureSession:(void (^)(AVCaptureSession* session))configuration {
    [self configureSession:configuration completion:nil];
}

- (void)configureSession:(void (^)(AVCaptureSession* session))configuration completion:(void (^)(void))completion {
    AVCaptureSession* session = self.session;
    dispatch_async(self.sessionQueue, ^{
        [session beginConfiguration];
        configuration(session);
        [session commitConfiguration];
        if (completion) {
            run_in_main_queue(completion);
        }
    });
}

- (void)configureDevice:(AVCaptureDevice*)device configuration:(void (^)(AVCaptureDevice* device))configuration {
	if ([device lockForConfiguration:nil]) {
		configuration(device);
		[device unlockForConfiguration];
	}
}

- (void)configureCurrentDevice:(void (^)(AVCaptureDevice* device))configuration {
	[self configureDevice:self.videoInput.device configuration:configuration];
}

- (void)setFlashMode:(AVCaptureFlashMode)flashMode {
    __weak typeof(self)weakSelf = self;
    [self configureSession:^(AVCaptureSession *session) {
        [weakSelf configureCurrentDevice:^(AVCaptureDevice *device) {
            if ([device isFlashModeSupported:flashMode]) {
                device.flashMode = flashMode;
            }
        }];
    }];
}

- (AVCaptureFlashMode)flashMode {
	return self.videoInput.device.flashMode;
}

- (BOOL)flashSupported {
    return self.videoInput.device.hasFlash;
}

- (void)autoFocusAtPoint:(CGPoint)point {
	__weak typeof(self)weakSelf = self;
	[self configureSession:^(AVCaptureSession *session) {
		[weakSelf configureCurrentDevice:^(AVCaptureDevice *device) {
			if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
				[device setFocusPointOfInterest:[weakSelf pointOfInterestFromPoint:point]];
				[device setFocusMode:AVCaptureFocusModeAutoFocus];
			}
		}];
	}];
}

- (void)autoExposureAtPoint:(CGPoint)point {
	__weak typeof(self)weakSelf = self;
	[self configureSession:^(AVCaptureSession *session) {
		[weakSelf configureCurrentDevice:^(AVCaptureDevice *device) {
			if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
				[device setExposurePointOfInterest:[weakSelf pointOfInterestFromPoint:point]];
				[device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
			}
		}];
	}];
}

- (void)autoFocusAndExposureAtPoint:(CGPoint)point {
	__weak typeof(self)weakSelf = self;
	[self configureSession:^(AVCaptureSession *session) {
		[weakSelf configureCurrentDevice:^(AVCaptureDevice *device) {
			CGPoint pointOfInterest = [weakSelf pointOfInterestFromPoint:point];
			if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
				[device setFocusPointOfInterest:pointOfInterest];
				[device setFocusMode:AVCaptureFocusModeAutoFocus];
			}
			if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
				[device setExposurePointOfInterest:pointOfInterest];
				[device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
			}
		}];
	}];
}

- (CGPoint)pointOfInterestFromPoint:(CGPoint)point {
    CGSize frameSize = self.cameraView.frame.size;
    CGSize apertureSize = CMVideoFormatDescriptionGetCleanAperture([[self videoPort] formatDescription], YES).size;
	CGSize scaledImageSize = CGSizeThatFillsSize(frameSize, apertureSize);
	CGRect visibleViewRect = CGRectThatFitsSize(scaledImageSize, frameSize);
    point.x += visibleViewRect.origin.x;
    point.y += visibleViewRect.origin.y;
    if ([self.stillImageOutputConnection isVideoMirrored]) {
        point.x = frameSize.width - point.x;
    }
	CGPoint pointOfInterest = CGPointMake(point.x/scaledImageSize.width, point.y/scaledImageSize.height);
    return pointOfInterest;
}

- (AVCaptureInputPort*)videoPort {
    for (AVCaptureInputPort *port in [self.videoInput ports]) {
        if ([port mediaType] == AVMediaTypeVideo) {
            return port;
        }
    }
    return nil;
}

- (void)setZoomScale:(CGFloat)zoomScale {
    AVCaptureDevice *device = self.videoInput.device;
	_zoomScale = Smoothstep(1, MIN(8, device.activeFormat.videoMaxZoomFactor), zoomScale);
    
    if (device.videoZoomFactor != _zoomScale) {
        if ([device lockForConfiguration:nil]) {
            [device setVideoZoomFactor:_zoomScale];
            [device unlockForConfiguration];
        }
    }
    
	[self showZoomLabel];
}

- (void)showZoomLabel {
	self.zoomLabel.text = [NSString stringWithFormat:@"%dx", (int)self.zoomScale];
	[UIView beginAnimations:nil context:nil];
	self.zoomLabel.alpha = 1.0f;
	[UIView commitAnimations];
	[self enqueueSelectorPerforming:@selector(hideZoomLabel) afterDelay:1.0f];
}

- (void)hideZoomLabel {
	[UIView beginAnimations:nil context:nil];
	self.zoomLabel.alpha = 0.0f;
	[UIView commitAnimations];
}

- (void)applyDeviceOrientation:(UIDeviceOrientation)orientation {
    if (orientation != UIDeviceOrientationUnknown) {
        [self applyDeviceOrientation:orientation forConnection:self.stillImageOutputConnection];
        [self applyDeviceOrientationToFunctionalButton:orientation];
    }
}

- (void)applyDeviceOrientationToFunctionalButton:(UIDeviceOrientation)orientation {
    [self.flashModeControl setSelecting:NO animated:YES];
    CGAffineTransform transform = CGAffineTransformIdentity;
    switch (orientation) {
        case UIDeviceOrientationLandscapeLeft:
            transform = CGAffineTransformMakeRotation(M_PI_2);
            break;
        case UIDeviceOrientationLandscapeRight:
            transform = CGAffineTransformMakeRotation(-M_PI_2);
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            transform = CGAffineTransformMakeRotation(M_PI);
            break;
        default:
            break;
    }
    [UIView animateWithDuration:.25 animations:^{
        self.backButton.transform = transform;
        self.rotateButton.transform = transform;
        self.videoRecordingTimeLabel.transform = transform;
        for (UIView *subView in self.flashModeControl.subviews) {
            subView.transform = transform;
        }
    }];
}

- (void)applyDeviceOrientation:(UIDeviceOrientation)orientation forConnection:(AVCaptureConnection*)connection {
    if (connection) {
        if (orientation == UIDeviceOrientationLandscapeLeft) {
            connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
        } else if (orientation == UIDeviceOrientationLandscapeRight) {
            connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
        } else if (orientation == UIDeviceOrientationPortrait) {
            connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        } else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
            connection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
        }
    }
}

#pragma mark - WLDeviceOrientationBroadcastReceiver

- (void)manager:(WLDeviceManager *)manager didChangeOrientation:(NSNumber*)orientation {
	[self applyDeviceOrientation:[orientation integerValue]];
}

// MARK: - AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    [self.videoRecordingIndicator.layer removeAnimationForKey:@"videoRecording"];
    self.cancelVideoRecordingLabel.hidden = YES;
    [self.videoRecordingTimer invalidate];
    [self prepareSessionForPhotoTaking];
    [self updateVideoRecordingViews:NO];
    self.videoRecordingView.hidden = YES;
    if (self.videoRecordingCancelled) {
        [[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:NULL];
    } else {
        if ([self.delegate respondsToSelector:@selector(cameraViewController:didFinishWithVideoAtPath:saveToAlbum:)]) {
            [self.delegate cameraViewController:self didFinishWithVideoAtPath:self.videoFilePath saveToAlbum:YES];
        }
    }
}

static NSTimeInterval videoRecordingTimerInterval = 0.03333333;

- (void)recordingTimerChanged:(NSTimer*)timer {
    NSTimeInterval videoRecordingTimeLeft = self.videoRecordingTimeLeft;
    if (videoRecordingTimeLeft > 0) {
        videoRecordingTimeLeft = MAX(0, videoRecordingTimeLeft - videoRecordingTimerInterval);
        self.videoRecordingTimeLeft = videoRecordingTimeLeft;
        self.videoRecordingTimeLabel.text =  [[@(ceilf(videoRecordingTimeLeft)) stringValue] stringByAppendingString:@"\""];
        self.videoRecordingProgressBar.progress = 1.0f - videoRecordingTimeLeft/maxVideoRecordedDuration;
    } else {
        [self.videoRecordingTimer invalidate];
    }
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.fromValue = @1;
    animation.toValue = @0;
    animation.autoreverses = YES;
    animation.duration = 0.5;
    animation.repeatCount = FLT_MAX;
    animation.removedOnCompletion = NO;
    [self.videoRecordingIndicator.layer addAnimation:animation forKey:@"videoRecording"];
    self.cancelVideoRecordingLabel.hidden = NO;
    self.videoRecordingTimeLeft = maxVideoRecordedDuration;
    self.videoRecordingTimeLabel.text = [@(maxVideoRecordedDuration) stringValue];
    self.videoRecordingProgressBar.progress = 0;
    self.videoRecordingView.hidden = NO;
    if (self.videoRecordingTimer) {
        [self.videoRecordingTimer invalidate];
    }
    self.videoRecordingTimer = [NSTimer scheduledTimerWithTimeInterval:videoRecordingTimerInterval target:self selector:@selector(recordingTimerChanged:) userInfo:nil repeats:YES];
}

// MARK: - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.view == self.view && [gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        CGPoint velocity = [gestureRecognizer velocityInView:self.view];
        return ABS(velocity.y) > ABS(velocity.x);
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end
