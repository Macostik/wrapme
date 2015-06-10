//
//  WLCameraViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 10.04.13.
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

@interface WLCameraViewController () <WLDeviceOrientationBroadcastReceiver>

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

@end

@implementation WLCameraViewController

@dynamic delegate;

- (void)dealloc {
    [[WLDeviceOrientationBroadcaster broadcaster] endUsingAccelerometer];
}

#pragma mark - View controller lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
	
    [[WLDeviceOrientationBroadcaster broadcaster] addReceiver:self];
    [[WLDeviceOrientationBroadcaster broadcaster] beginUsingAccelerometer];
    
	if (self.presentingViewController) {
		self.view.frame = self.presentingViewController.view.bounds;
        [self.view layoutIfNeeded];
	}
    
    self.cropAreaView.layer.borderWidth = 1;
    self.cropAreaView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.25].CGColor;
    
    __weak typeof(self)weakSelf = self;
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        run_in_main_queue(^{
            weakSelf.unauthorizedStatusView.hidden = granted;
            if (granted) {
                AVCaptureDevicePosition defaultPosition = AVCaptureDevicePositionBack;
                AVCaptureFlashMode flashMode = AVCaptureFlashModeOff;
                if (weakSelf.mode == WLStillPictureModeDefault) {
                    NSNumber *savedDefaultPosition = [WLSession object:@"WLCameraDefaultPosition"];
                    if (savedDefaultPosition) defaultPosition = [savedDefaultPosition integerValue];
                    NSNumber *savedFlashMode = [WLSession object:@"WLCameraDefaultFlashMode"];
                    if (savedFlashMode) flashMode = [savedFlashMode integerValue];
                } else {
                    defaultPosition = AVCaptureDevicePositionFront;
                }
                weakSelf.position = defaultPosition;
                weakSelf.flashMode = weakSelf.flashModeControl.mode = flashMode;
                weakSelf.cameraView.layer.session = weakSelf.session;
                [weakSelf start];
            } else {
                weakSelf.takePhotoButton.active = NO;
            }
        });
    }];
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
	__weak typeof(self)weakSelf = self;
	self.view.userInteractionEnabled = NO;
	sender.active = NO;
	[self captureImage:^(UIImage *image, NSMutableDictionary* metadata) {
        [UIView animateWithDuration:0.1 animations:^{
            weakSelf.cameraView.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1 animations:^{
                weakSelf.cameraView.alpha = 1.0f;
            }];
        }];
		[weakSelf finishWithImage:image metadata:metadata];
		weakSelf.view.userInteractionEnabled = YES;
        run_after(0.5f, ^{
            sender.active = YES;
        });
	}];
}

- (IBAction)gallery:(id)sender {
	[self.delegate cameraViewControllerDidSelectGallery:self];
}

- (IBAction)finish:(id)sender {
    if ([self.delegate respondsToSelector:@selector(cameraViewControllerDidFinish:)]) {
        [self.delegate cameraViewControllerDidFinish:self];
    }
}

- (void)finishWithImage:(UIImage*)image metadata:(NSMutableDictionary*)metadata {
	[self.delegate cameraViewController:self didFinishWithImage:image metadata:metadata];
}

- (IBAction)flashModeChanged:(WLFlashModeControl *)sender {
	self.flashMode = sender.mode;
	if (self.flashMode != sender.mode) {
		sender.mode = self.flashMode;
	}
    if (self.mode == WLStillPictureModeDefault) {
        [WLSession setObject:@(self.flashMode) key:@"WLCameraDefaultFlashMode"];
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
            [WLSession setObject:@(self.position) key:@"WLCameraDefaultPosition"];
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
    if (!self.session.isRunning) {
        [self.session startRunning];
    }
}

- (void)stop {
    if (self.session.isRunning) {
        [self.session stopRunning];
    }
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

- (void)captureImage:(void (^)(UIImage*image, NSMutableDictionary* metadata))completion {
#if TARGET_IPHONE_SIMULATOR
	run_getting_object(^id{
        CGSize size = CGSizeMake(720, 720);
        size = [UIScreen mainScreen].bounds.size;
		NSString* url = url = [NSString stringWithFormat:@"http://placeimg.com/%d/%d/any", (int)size.width, (int)size.height];
		return [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:url]]];
	}, ^ (UIImage* image) {
		completion(image, nil);
	});
	return;
#endif
	
	void (^handler) (CMSampleBufferRef, NSError *) = ^(CMSampleBufferRef buffer, NSError *error) {
		UIImage* image = nil;
		NSMutableDictionary* metadata = nil;
		if (!error) {
			NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:buffer];
			image = [[UIImage alloc] initWithData:imageData];
			metadata = [[NSMutableDictionary alloc] initWithImageSampleBuffer:buffer];
		}
		completion(image, metadata);
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
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideZoomLabel) object:nil];
	[self performSelector:@selector(hideZoomLabel) withObject:nil afterDelay:1.0f];
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
