//
//  WLCameraViewController.m
//  moji
//
//  Created by Ravenpod on 10.04.13.
//
//

#import "WLCameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import "UIImage+Resize.h"
#import "NSMutableDictionary+ImageMetadata.h"
#import "UIButton+Additions.h"
#import "WLFlashModeControl.h"
#import "WLCameraAdjustmentView.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "WLDeviceOrientationBroadcaster.h"
#import "ALAssetsLibrary+Additions.h"
#import "WLToast.h"
#import "WLWrapView.h"
#import "WLQuickAssetsViewController.h"

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
    self.layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
}

@end

@interface WLCameraViewController () <WLDeviceOrientationBroadcastReceiver, UIGestureRecognizerDelegate>

#pragma mark - AVCaptureSession interface

@property (strong, nonatomic) AVCaptureStillImageOutput *output;
@property (strong, nonatomic) AVCaptureDeviceInput *input;
@property (nonatomic, strong) AVCaptureSession* session;
@property (nonatomic, weak) AVCaptureConnection* connection;
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
@property (weak, nonatomic) IBOutlet UIButton *galleryButton;

@property (weak, nonatomic) WLQuickAssetsViewController* assetsViewController;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *assetsBottomConstraint;
@property (weak, nonatomic) IBOutlet UILabel *assetsArrow;

@property (strong, nonatomic) dispatch_queue_t sessionQueue;

@end

@implementation WLCameraViewController

@synthesize wrapView = _wrapView;

@dynamic delegate;

- (void)dealloc {
    [[WLDeviceOrientationBroadcaster broadcaster] endUsingAccelerometer];
}

#pragma mark - View controller lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
    
    self.sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
	
    [[WLDeviceOrientationBroadcaster broadcaster] addReceiver:self];
    [[WLDeviceOrientationBroadcaster broadcaster] beginUsingAccelerometer];
    
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
    } failure:^(NSError *error) {
        weakSelf.unauthorizedStatusView.hidden = NO;
        weakSelf.takePhotoButton.active = NO;
    }];
    
    for (WLQuickAssetsViewController *assetsViewController in self.childViewControllers) {
        if ([assetsViewController isKindOfClass:[WLQuickAssetsViewController class]]) {
            self.assetsViewController = assetsViewController;
            self.assetsViewController.delegate = self.delegate;
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
    if ([self.delegate respondsToSelector:@selector(cameraViewControllerShouldTakePhoto:)]) {
        if ([self.delegate cameraViewControllerShouldTakePhoto:self] == NO) {
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
    
    [self captureImage:^{
    } result:^(UIImage *image, NSMutableDictionary *metadata) {
        [weakSelf finishWithImage:image metadata:metadata];
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
    if ([self.delegate respondsToSelector:@selector(cameraViewControllerDidFinish:sender:)]) {
        [self.delegate cameraViewControllerDidFinish:self sender:sender];
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

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.view == self.view && [gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        CGPoint velocity = [gestureRecognizer velocityInView:self.view];
        return ABS(velocity.y) > ABS(velocity.x);
    }
    return YES;
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

- (void)finishWithImage:(UIImage*)image metadata:(NSMutableDictionary*)metadata {
    [self.delegate cameraViewController:self didFinishWithImage:image metadata:metadata saveToAlbum:YES];
}

- (IBAction)flashModeChanged:(WLFlashModeControl *)sender {
	self.flashMode = sender.mode;
	if (self.flashMode != sender.mode) {
		sender.mode = self.flashMode;
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
        NSString* url = url = [NSString stringWithFormat:@"http://placeimg.com/%d/%d/any", (int)size.width, (int)size.height];
        return [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:url]]];
    }, ^ (UIImage* image) {
        if (image) {
            [weakSelf.delegate cameraViewController:weakSelf didFinishWithImage:image metadata:nil saveToAlbum:NO];
        }
        weakSelf.takePhotoButton.active = YES;
    });
}

#pragma mark - AVCaptureSession

- (AVCaptureDevice*)deviceWithPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devices];
    for (AVCaptureDevice *device in devices) {
        if ([device hasMediaType:AVMediaTypeVideo]) {
            if ([device position] == position)
                return device;
        }
    }
    return nil;
}

- (AVCaptureDeviceInput*)inputWithPosition:(AVCaptureDevicePosition)position {
    AVCaptureDevice *deviceInput = [self deviceWithPosition:position];
    if (deviceInput) {
        [deviceInput lockForConfiguration:nil];
        if ([deviceInput isFocusModeSupported:AVCaptureFocusModeAutoFocus])
            deviceInput.focusMode = AVCaptureFocusModeAutoFocus;
        [deviceInput unlockForConfiguration];
        NSError *error = nil;
        id input = [AVCaptureDeviceInput deviceInputWithDevice:deviceInput error:&error];
        return input;
    }
    return nil;
}

- (void)setInput:(AVCaptureDeviceInput *)input {
	AVCaptureSession* session = self.session;
	[session beginConfiguration];
	for (AVCaptureDeviceInput* input in session.inputs) {
		[session removeInput:input];
	}
	if ([session canAddInput:input]) {
		[session addInput:input];
	}
	[session commitConfiguration];
	self.flashModeControl.hidden = !self.input.device.hasFlash;
    self.connection = nil;
	[self applyDeviceOrientation:[WLDeviceOrientationBroadcaster broadcaster].orientation];
}

- (AVCaptureDeviceInput *)input {
	return [self.session.inputs lastObject];
}

- (AVCaptureSession *)session {
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
        if ([_session canSetSessionPreset:AVCaptureSessionPresetPhoto]) {
            _session.sessionPreset = AVCaptureSessionPresetPhoto;
        } else {
            _session.sessionPreset = AVCaptureSessionPresetMedium;
        }
        [_session addOutput:self.output];
    }
    return _session;
}

- (AVCaptureStillImageOutput *)output {
	if (!_output) {
		_output = [[AVCaptureStillImageOutput alloc] init];
		[_output setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
	}
	return _output;
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

- (AVCaptureConnection*)connection {
	if (!_connection) {
		for (AVCaptureConnection *connection in [self.output connections]) {
			for (AVCaptureInputPort *port in [connection inputPorts]) {
				if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
					_connection = connection;
					_connection.videoOrientation = AVCaptureVideoOrientationPortrait;
					break;
				}
			}
			if (_connection) {
				break;
			}
		}
	}
    return _connection;
}

- (void)captureImage:(WLBlock)completion result:(void (^)(UIImage*image, NSMutableDictionary* metadata))result failure:(WLFailureBlock)failure {
#if TARGET_IPHONE_SIMULATOR
	run_getting_object(^id{
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        CGSize size = CGSizeMake(width, width / 0.75);
		NSString* url = url = [NSString stringWithFormat:@"http://placeimg.com/%d/%d/any", (int)size.width, (int)size.height];
		return [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:url]]];
	}, ^ (UIImage* image) {
        if (image) {
            if (completion) completion();
            if (result) result(image, nil);
        } else {
            if (failure) failure(nil);
        }
	});
	return;
#endif
	
	void (^handler) (CMSampleBufferRef, NSError *) = ^(CMSampleBufferRef buffer, NSError *error) {
		if (!error) {
            if (completion) completion();
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:buffer];
            NSMutableDictionary* metadata = [[NSMutableDictionary alloc] initWithImageSampleBuffer:buffer];
            UIImage* image = [[UIImage alloc] initWithData:imageData];
            if (result) result(image, metadata);
        } else {
            if (failure) failure(error);
        }
	};
    AVCaptureConnection *connection = self.connection;
    self.takePhotoButton.active = connection == nil;
	connection.videoMirrored = (self.position == AVCaptureDevicePositionFront);
    [self.output captureStillImageAsynchronouslyFromConnection:connection completionHandler:handler];
}

- (AVCaptureDevicePosition)position {
	return self.input.device.position;
}

- (void)setPosition:(AVCaptureDevicePosition)position {
    [self setPosition:position animated:NO];
}

- (void)setPosition:(AVCaptureDevicePosition)position animated:(BOOL)animated {
	self.input = [self inputWithPosition:position];
}

- (void)configureSession:(void (^)(AVCaptureSession* session))configuration {
	AVCaptureSession* session = self.session;
	[session beginConfiguration];
	configuration(session);
	[session commitConfiguration];
}

- (void)configureDevice:(AVCaptureDevice*)device configuration:(void (^)(AVCaptureDevice* device))configuration {
	if ([device lockForConfiguration:nil]) {
		configuration(device);
		[device unlockForConfiguration];
	}
}

- (void)configureCurrentDevice:(void (^)(AVCaptureDevice* device))configuration {
	[self configureDevice:self.input.device configuration:configuration];
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
	return self.input.device.flashMode;
}

- (BOOL)flashSupported {
    return self.input.device.hasFlash;
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
    if ([self.connection isVideoMirrored]) {
        point.x = frameSize.width - point.x;
    }
	CGPoint pointOfInterest = CGPointMake(point.x/scaledImageSize.width, point.y/scaledImageSize.height);
    return pointOfInterest;
}

- (AVCaptureInputPort*)videoPort {
    for (AVCaptureInputPort *port in [self.input ports]) {
        if ([port mediaType] == AVMediaTypeVideo) {
            return port;
        }
    }
    return nil;
}

- (void)setZoomScale:(CGFloat)zoomScale {
    AVCaptureDevice *device = self.input.device;
	_zoomScale = Smoothstep(1, MIN(8, device.activeFormat.videoMaxZoomFactor), zoomScale);
    
    if (device.videoZoomFactor != _zoomScale) {
        // iOS 7.x with compatible hardware
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
        [self applyDeviceOrientation:orientation forConnection:self.connection];
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
        self.galleryButton.transform = transform;
        for (UIView *subView in self.flashModeControl.subviews) {
            subView.transform = transform;
        }
    }];
}

- (void)applyDeviceOrientation:(UIDeviceOrientation)orientation forConnection:(AVCaptureConnection*)connection {
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

#pragma mark - WLDeviceOrientationBroadcastReceiver

- (void)broadcaster:(WLDeviceOrientationBroadcaster *)broadcaster didChangeOrientation:(NSNumber*)orientation {
	[self applyDeviceOrientation:[orientation integerValue]];
}

@end
