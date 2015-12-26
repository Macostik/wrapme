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
#import <MobileCoreServices/MobileCoreServices.h>
#import "WLDeviceManager.h"
#import "WLToast.h"
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

@interface WLCameraViewController () <WLDeviceManagerReceiver, UIGestureRecognizerDelegate, AVCaptureFileOutputRecordingDelegate>

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
@property (weak, nonatomic) IBOutlet FlashModeControl *flashModeControl;
@property (weak, nonatomic) IBOutlet UIButton *rotateButton;
@property (weak, nonatomic) IBOutlet UILabel *zoomLabel;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@property (weak, nonatomic) AssetsViewController* assetsViewController;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *assetsBottomConstraint;
@property (weak, nonatomic) IBOutlet UILabel *assetsArrow;
@property (weak, nonatomic) IBOutlet UIView *assetsView;

@property (strong, nonatomic) dispatch_queue_t sessionQueue;

@property (weak, nonatomic) NSTimer *videoRecordingTimer;
@property (weak, nonatomic) NSTimer *startVideoRecordingTimer;


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cameraViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewHeightConstraint;
@property (weak, nonatomic) IBOutlet ProgressBar *videoRecordingProgressBar;
@property (weak, nonatomic) IBOutlet UIView *videoRecordingView;
@property (weak, nonatomic) IBOutlet UILabel *videoRecordingTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *cancelVideoRecordingLabel;
@property (weak, nonatomic) IBOutlet UIView *videoRecordingIndicator;

@property (weak, nonatomic) AVCaptureDeviceInput *audioInput;

@property (nonatomic) BOOL videoRecordingCancelled;

@property (nonatomic) NSTimeInterval videoRecordingTimeLeft;

@property (strong, nonatomic) NSString *videoFilePath;

@property (weak, nonatomic) UIView *focusView;

@end

@implementation WLCameraViewController

@synthesize wrapView = _wrapView;

@dynamic delegate;

- (void)dealloc {
    [[WLDeviceManager defaultManager] endUsingAccelerometer];
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
	
    [[WLDeviceManager defaultManager] addReceiver:self];
    [[WLDeviceManager defaultManager] beginUsingAccelerometer];
    
    self.cropAreaView.borderWidth = 1;
    self.cropAreaView.borderColor = [UIColor colorWithWhite:1 alpha:0.25];
    
    __weak typeof(self)weakSelf = self;
    
    if (self.mode == StillPictureModeDefault) {
        UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(startVideoRecording:)];
        recognizer.delegate = self;
        [self.takePhotoButton addGestureRecognizer:recognizer];
    }
    
    [self authorize:^{
        AVCaptureDevicePosition position = AVCaptureDevicePositionBack;
        AVCaptureFlashMode flashMode = AVCaptureFlashModeOff;
        if (weakSelf.mode == StillPictureModeDefault) {
            NSNumber *savedPosition = [NSUserDefaults standardUserDefaults].cameraDefaultPosition;
            if (savedPosition) position = [savedPosition integerValue];
            NSNumber *savedFlashMode = [NSUserDefaults standardUserDefaults].cameraDefaultFlashMode;
            if (savedFlashMode) flashMode = [savedFlashMode integerValue];
        } else {
            position = AVCaptureDevicePositionFront;
        }
        weakSelf.position = position;
        weakSelf.flashMode = weakSelf.flashModeControl.mode = flashMode;
        weakSelf.cameraView.layer.session = weakSelf.session;
        [weakSelf start];
    } failure:^(NSError *error) {
        weakSelf.unauthorizedStatusView.hidden = NO;
        weakSelf.takePhotoButton.active = NO;
    }];
    
    for (AssetsViewController *assetsViewController in self.childViewControllers) {
        if ([assetsViewController isKindOfClass:[AssetsViewController class]]) {
            self.assetsViewController = assetsViewController;
            self.assetsViewController.delegate = self.delegate;
            self.assetsViewController.mode = self.mode;
            break;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self enqueueSelector:@selector(setAssetsViewControllerHidden) delay:4.0];
    __weak __typeof(self)weakSelf = self;
    self.assetsViewController.assetsHidingHandler = ^ {
        [NSObject cancelPreviousPerformRequestsWithTarget:weakSelf selector:@selector(setAssetsViewControllerHidden) object:nil];
    };
}

- (void)authorize:(Block)success failure:(FailureBlock)failure {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusAuthorized) {
        if (success) success();
    } else if (status == AVAuthorizationStatusDenied || status == AVAuthorizationStatusRestricted) {
        if (failure) failure(nil);
    } else {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            [[Dispatch mainQueue] async:^{
                if (granted) {
                    if (success) success();
                } else {
                    if (failure) failure(nil);
                }
            }];
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
        sender.active = YES;
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

- (void)setAssetsViewControllerHidden {
    [self setAssetsViewControllerHidden:YES animated:YES];
}

- (void)setAssetsViewControllerHidden:(BOOL)hidden animated:(BOOL)animated {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setAssetsViewControllerHidden) object:nil];
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

- (IBAction)flashModeChanged:(FlashModeControl *)sender {
    __weak typeof(self)weakSelf = self;
    AVCaptureFlashMode flashMode = sender.mode;
    [self configureDevice:^(AVCaptureDevice *device) {
        if ([device isFlashModeSupported:flashMode]) {
            device.flashMode = flashMode;
            if (weakSelf.mode == StillPictureModeDefault) {
                [NSUserDefaults standardUserDefaults].cameraDefaultFlashMode = @(flashMode);
            }
        } else {
            sender.mode = device.flashMode;
        }
    }];
}

- (IBAction)rotateCamera:(id)sender {
	if (self.position == AVCaptureDevicePositionBack) {
		self.position = AVCaptureDevicePositionFront;
	} else {
		self.position = AVCaptureDevicePositionBack;
	}
	self.flashMode = self.flashModeControl.mode;
    self.zoomScale = 1;
    if (self.mode == StillPictureModeDefault) {
        if (self.position != AVCaptureDevicePositionUnspecified)
            [NSUserDefaults standardUserDefaults].cameraDefaultPosition = @(self.position);
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
	
    if (self.focusView) {
        [self.focusView removeFromSuperview];
    }
	
	CGPoint point = [sender locationInView:self.cameraView];
    [self autoFocusAndExposureAtPoint:point];
	UIView *focusView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 67, 67)];
	focusView.center = point;
	focusView.userInteractionEnabled = NO;
    focusView.backgroundColor = [UIColor clearColor];
    focusView.borderColor = [Color.orange colorWithAlphaComponent:0.5f];
    focusView.borderWidth = 1;
	[self.cameraView addSubview:focusView];
    self.focusView = focusView;
	[UIView animateWithDuration:0.33f delay:1.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		focusView.alpha = 0.0f;
	} completion:^(BOOL finished) {
		[focusView removeFromSuperview];
	}];
}

- (IBAction)getSamplePhoto:(id)sender {
    self.takePhotoButton.active = NO;
    __weak typeof(self)weakSelf = self;
    [[Dispatch defaultQueue] fetch:^id _Nullable{
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        CGSize size = CGSizeMake(width, width / 0.75);
        NSString* url = [NSString stringWithFormat:@"http://placeimg.com/%d/%d/any", (int)size.width, (int)size.height];
        return [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[url URL]]];
    } completion:^(UIImage *image) {
        if (image) {
            [weakSelf.delegate cameraViewController:weakSelf didFinishWithImage:image saveToAlbum:NO];
        }
        weakSelf.takePhotoButton.active = YES;
    }];
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
        case UIGestureRecognizerStateChanged: {
            CGPoint location = [sender locationInView:self.videoRecordingView];
            if (self.movieFileOutput.recording && !self.videoRecordingCancelled) {
                if (location.x < Constants.screenWidth/4) {
                    [self cancelVideoRecording];
                }
            }
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

- (void)prepareSessionForVideoRecording:(Block)preparingCompletion {
    __weak typeof(self)weakSelf = self;
    if (![self.session.outputs containsObject:self.movieFileOutput]) {
        [self blurCamera:^(Block completion) {
            
            AVCaptureSession* session = weakSelf.session;
            AVCaptureDevice *device = weakSelf.videoInput.device;
            AVCaptureTorchMode torchMode = (AVCaptureTorchMode)weakSelf.flashMode;
            dispatch_async(weakSelf.sessionQueue, ^{
                [session beginConfiguration];
                
                AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio] error:nil];
                if ([session canAddInput:input]) {
                    [session addInput:input];
                }
                weakSelf.audioInput = input;
                [session removeOutput:weakSelf.stillImageOutput];
                if ([session canAddOutput:weakSelf.movieFileOutput]) {
                    [session addOutput:weakSelf.movieFileOutput];
                }
                
                AVCaptureDeviceFormat *activeFormat = nil;
                
                CGFloat targetRatio = (CGFloat)16.0f/(CGFloat)9.0f;
                
                for (AVCaptureDeviceFormat *format in device.formats) {
                    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
                    CGFloat ratio = (CGFloat)dimensions.width / (CGFloat)dimensions.height;
                    if (ratio == targetRatio) {
                        activeFormat = format;
                        break;
                    }
                }
                
                session.sessionPreset = activeFormat ? AVCaptureSessionPresetInputPriority : AVCaptureSessionPresetMedium;
                
                [session commitConfiguration];
                
                if ([device lockForConfiguration:nil]) {
                    
                    if (activeFormat) {
                        device.activeFormat = activeFormat;
                    }
                    
                    device.videoZoomFactor = Smoothstep(1, MIN(8, device.activeFormat.videoMaxZoomFactor), _zoomScale);
                    if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                        [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
                    }
                    if (device.hasTorch && device.torchAvailable && [device isTorchModeSupported:torchMode]) {
                        device.torchMode = torchMode;
                    }
                    [device unlockForConfiguration];
                }
                [[Dispatch mainQueue] async:^{
                    weakSelf.cameraView.layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
                    [weakSelf applyDeviceOrientation:[WLDeviceManager defaultManager].orientation forConnection:weakSelf.movieFileOutputConnection];
                    completion();
                    preparingCompletion();
                }];
            });
        }];
    }
}

- (void)blurCamera:(void (^)(Block completion))handler {
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
        [self blurCamera:^(Block completion) {
            [weakSelf configureSession:^(AVCaptureSession *session) {
                session.sessionPreset = AVCaptureSessionPresetPhoto;
                [session removeInput:weakSelf.audioInput];
                [session removeOutput:weakSelf.movieFileOutput];
                if ([session canAddOutput:weakSelf.stillImageOutput]) {
                    [session addOutput:weakSelf.stillImageOutput];
                }
            } completion:^{
                weakSelf.cameraView.layer.videoGravity = AVLayerVideoGravityResizeAspect;
                [weakSelf configureDevice:^(AVCaptureDevice *device) {
                    device.videoZoomFactor = Smoothstep(1, MIN(8, device.activeFormat.videoMaxZoomFactor), _zoomScale);
                    if ([device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
                        [device setFocusMode:AVCaptureFocusModeAutoFocus];
                    }
                    if ([device isTorchModeSupported:AVCaptureTorchModeOff]) {
                        device.torchMode = AVCaptureTorchModeOff;
                    }
                }];
                [weakSelf applyDeviceOrientation:[WLDeviceManager defaultManager].orientation forConnection:weakSelf.stillImageOutputConnection];
                weakSelf.takePhotoButton.userInteractionEnabled = YES;
                completion();
            }];
        }];
    }
}

- (void)startVideoRecording {
    self.videoRecordingCancelled = NO;
    NSString *videosDirectoryPath = [NSHomeDirectory() stringByAppendingString:@"/Documents/Videos"];
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
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] selectObject:^BOOL(AVCaptureDevice *device) {
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
	[self applyDeviceOrientation:[WLDeviceManager defaultManager].orientation];
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
        CMTime maxDuration = CMTimeMakeWithSeconds([Constants maxVideoRecordedDuration], NSEC_PER_SEC);
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

- (void)captureImage:(void (^)(UIImage*image))result failure:(FailureBlock)failure {
#if TARGET_OS_SIMULATOR
	[[Dispatch defaultQueue] fetch:^id _Nullable{
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        CGSize size = CGSizeMake(width, width / 0.75);
		NSString* url = url = [NSString stringWithFormat:@"http://placeimg.com/%d/%d/any", (int)size.width, (int)size.height];
		return [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[url URL]]];
	} completion:^(UIImage* image) {
        if (image) {
            if (result) result(image);
        } else {
            if (failure) failure(nil);
        }
	}];
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
    
    
    dispatch_async(self.sessionQueue, ^{
        [[Dispatch mainQueue] async:^{
            AVCaptureStillImageOutput *output = self.stillImageOutput;
            AVCaptureConnection *connection = [output connectionWithMediaType:AVMediaTypeVideo];
            if (connection && [self.session.outputs containsObject:output]) {
                connection.videoMirrored = (self.position == AVCaptureDevicePositionFront);
                [output captureStillImageAsynchronouslyFromConnection:connection completionHandler:handler];
            } else {
                if (failure) failure(nil);
            }
        }];
    });
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
            [[Dispatch mainQueue] async:completion];
        }
    });
}

- (void)configureDevice:(void (^)(AVCaptureDevice* device))configuration {
    AVCaptureDevice *device = self.videoInput.device;
    if ([device lockForConfiguration:nil]) {
        configuration(device);
        [device unlockForConfiguration];
    }
}

- (void)setFlashMode:(AVCaptureFlashMode)flashMode {
    [self configureDevice:^(AVCaptureDevice *device) {
        if ([device lockForConfiguration:nil]) {
            if ([device isFlashModeSupported:flashMode]) {
                device.flashMode = flashMode;
            }
            [device unlockForConfiguration];
        }
    }];
}

- (AVCaptureFlashMode)flashMode {
	return self.videoInput.device.flashMode;
}

- (void)autoFocusAndExposureAtPoint:(CGPoint)point {
    __weak typeof(self)weakSelf = self;
    [self configureDevice:^(AVCaptureDevice *device) {
        CGPoint pointOfInterest = [weakSelf.cameraView.layer captureDevicePointOfInterestForPoint:point];
        if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [device setFocusPointOfInterest:pointOfInterest];
            [device setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
            [device setExposurePointOfInterest:pointOfInterest];
            [device setExposureMode:AVCaptureExposureModeAutoExpose];
        }
    }];
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
    [self.zoomLabel setAlpha:1.0f animated:YES];
	[self enqueueSelector:@selector(hideZoomLabel) delay:1.0f];
}

- (void)hideZoomLabel {
	[self.zoomLabel setAlpha:0.0f animated:YES];
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
        self.takePhotoButton.transform = transform;
        self.finishButton.transform = transform;
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

#pragma mark - WLDeviceManagerReceiver

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
        self.videoRecordingProgressBar.progress = 1.0f - videoRecordingTimeLeft/[Constants maxVideoRecordedDuration];
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
    self.videoRecordingTimeLeft = [Constants maxVideoRecordedDuration];
    self.videoRecordingTimeLabel.text = [@([Constants maxVideoRecordedDuration]) stringValue];
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
