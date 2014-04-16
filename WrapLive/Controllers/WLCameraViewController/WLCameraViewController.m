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
#import "WLSupportFunctions.h"
#import "UIImage+Resize.h"
#import "UIColor+CustomColors.h"
#import "UIView+Shorthand.h"
#import "ALAssetsLibrary+CustomPhotoAlbum.h"
#import "WLCameraInteractionView.h"
#import "NSMutableDictionary+ImageMetadata.h"
#import "UIButton+Additions.h"

@interface WLCameraViewController () <WLCameraInteractionViewDelegate>

#pragma mark - AVCaptureSession interface

@property (strong, nonatomic) AVCaptureStillImageOutput *output;
@property (strong, nonatomic) AVCaptureDeviceInput *input;
@property (nonatomic, strong) AVCaptureSession* session;
@property (nonatomic, weak) AVCaptureConnection* connection;

#pragma mark - UIKit interface

@property (weak, nonatomic) IBOutlet UIView *cameraView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIImageView *acceptImageView;
@property (weak, nonatomic) IBOutlet UIView *acceptView;
@property (weak, nonatomic) IBOutlet UIView *acceptButtonsView;
@property (weak, nonatomic) IBOutlet UIButton *takePhotoButton;

@property (nonatomic, strong) NSMutableDictionary* metadata;

@end

@implementation WLCameraViewController

#pragma mark - View controller lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
	
	if (self.presentingViewController) {
		self.view.frame = self.presentingViewController.view.bounds;
	}
	
	self.position = self.defaultPosition;
    
	if (self.mode == WLCameraModeFullSize) {
		self.topView.backgroundColor = [UIColor clearColor];
		self.cameraView.y = 0;
		self.cameraView.height = self.view.height - 58;
	} else {
		self.cameraView.y = self.topView.bottom;
		self.cameraView.height = self.cameraView.width;
		if ([UIScreen mainScreen].bounds.size.height >= 568) {
			[self.takePhotoButton setImage:[UIImage imageNamed:@"camera_big"] forState:UIControlStateNormal];
		}
	}
	self.bottomView.y = self.cameraView.bottom;
	self.bottomView.height = self.view.height - self.bottomView.y;
	[self configurePreviewLayer];
	
	[self performSelector:@selector(start) withObject:nil afterDelay:0.0];
}

- (void)configurePreviewLayer {
	AVCaptureVideoPreviewLayer* previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
	previewLayer.frame = self.cameraView.bounds;
	previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	[self.cameraView.layer insertSublayer:previewLayer atIndex:0];
}

#pragma mark - User Actions

- (IBAction)cancel:(id)sender {
	if (self.delegate) {
		[self.delegate cameraViewControllerDidCancel:self];
	} else if (self.presentingViewController) {
		[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
	}
}

- (IBAction)shot:(UIButton*)sender {
	__weak typeof(self)weakSelf = self;
	self.view.userInteractionEnabled = NO;
	sender.active = NO;
	[self captureImage:^(UIImage *image) {
		[weakSelf cropImage:image completion:^(UIImage *croppedImage) {
			[weakSelf setAcceptImage:croppedImage animated:YES];
			weakSelf.view.userInteractionEnabled = YES;
			sender.active = YES;
		}];
	}];
}

- (void)cropImage:(UIImage*)image completion:(void (^)(UIImage *croppedImage))completion {
	if (self.mode == WLCameraModeFullSize) {
		completion(image);
	} else {
		CGSize viewSize = self.cameraView.bounds.size;
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			
			UIImage *result = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill
																bounds:CGSizeMake(640, 640)
												  interpolationQuality:kCGInterpolationDefault];
			
			CGRect cropRect = CGRectThatFitsSize(result.size, viewSize);
			result = [result croppedImage:cropRect];
			dispatch_async(dispatch_get_main_queue(), ^{
				completion(result);
			});
		});
	}
}

- (IBAction)retake:(id)sender {
	[self setAcceptImage:nil animated:YES];
}

- (IBAction)use:(id)sender {
	UIImage* image = self.acceptImageView.image;
	[self saveImage:image];
	[self.delegate cameraViewController:self didFinishWithImage:image];
}

- (void)setAcceptImage:(UIImage *)acceptImage animated:(BOOL)animated {
	
	if (acceptImage) {
		self.acceptView.hidden = NO;
		self.acceptButtonsView.transform = CGAffineTransformMakeTranslation(0, self.acceptButtonsView.frame.size.height);
		self.acceptView.backgroundColor = [UIColor clearColor];
	}
	
	[UIView animateWithDuration:animated ? 0.25f : 0.0f animations:^{
		if (acceptImage) {
			self.acceptButtonsView.transform = CGAffineTransformIdentity;
			self.acceptView.backgroundColor = [UIColor whiteColor];
		} else {
			self.acceptImageView.image = nil;
			self.acceptButtonsView.transform = CGAffineTransformMakeTranslation(0, self.acceptButtonsView.frame.size.height);
			self.acceptView.backgroundColor = [UIColor clearColor];
		}
	} completion:^(BOOL finished) {
		if (!acceptImage) {
			self.acceptView.hidden = YES;
		} else {
			self.acceptImageView.image = acceptImage;
		}
	}];
}

- (void)saveImage:(UIImage*)image {
	__weak typeof(self)weakSelf = self;
	[self.metadata setImageOrientation:image.imageOrientation];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
		[library saveImage:image
				   toAlbum:@"WrapLive"
				  metadata:weakSelf.metadata
				completion:^(NSURL *assetURL, NSError *error) { }
				   failure:^(NSError *error) { }];
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
        return [AVCaptureDeviceInput deviceInputWithDevice:deviceInput error:NULL];
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

- (void)captureImage:(void (^)(UIImage*image))completion {
	__weak typeof(self)weakSelf = self;
#if TARGET_IPHONE_SIMULATOR
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		UIImage* image = nil;
		if (self.mode == WLCameraModeFullSize) {
			image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://placeimg.com/640/480/nature"]]];
		} else {
			image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://placeimg.com/640/640/nature"]]];
		}
        dispatch_async(dispatch_get_main_queue(), ^{
			completion(image);
        });
    });
	return;
#endif
	
	void (^handler) (CMSampleBufferRef, NSError *) = ^(CMSampleBufferRef buffer, NSError *error) {
		UIImage* image = nil;
		if (!error) {
			NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:buffer];
			image = [[UIImage alloc] initWithData:imageData];
			weakSelf.metadata = [[NSMutableDictionary alloc] initWithImageSampleBuffer:buffer];
		}
		completion(image);
	};
    [self.output captureStillImageAsynchronouslyFromConnection:self.connection completionHandler:handler];
}

- (AVCaptureDevicePosition)defaultPosition {
	if (_defaultPosition == AVCaptureDevicePositionUnspecified) {
		_defaultPosition = AVCaptureDevicePositionBack;
	}
	return _defaultPosition;
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
				[device setFocusPointOfInterest:[self pointOfInterestFromPoint:point]];
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
				[device setExposurePointOfInterest:[self pointOfInterestFromPoint:point]];
				[device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
			}
		}];
	}];
}

- (CGPoint)pointOfInterestFromPoint:(CGPoint)point {
    CGSize frameSize = self.cameraView.frame.size;
    CGSize apertureSize = CMVideoFormatDescriptionGetCleanAperture([[self videoPort] formatDescription], YES).size;
    CGRect visibleRect = CGRectThatFitsSize(apertureSize, frameSize);
    point.x += visibleRect.origin.x;
    point.y += visibleRect.origin.y;
    if ([self.connection isVideoMirrored]) {
        point.x = frameSize.width - point.x;
    }
    return CGPointMake(point.x/apertureSize.width, point.y/apertureSize.height);
}

- (AVCaptureInputPort*)videoPort {
    for (AVCaptureInputPort *port in [self.input ports]) {
        if ([port mediaType] == AVMediaTypeVideo) {
            return port;
        }
    }
    return nil;
}

#pragma mark - PGCameraInteractionViewDelegate

- (void)cameraInteractionView:(WLCameraInteractionView *)view didChangeExposure:(CGPoint)exposure {
    if(![self.session isRunning]) {
        return;
    }
    [self autoExposureAtPoint:exposure];
}

- (void)cameraInteractionView:(WLCameraInteractionView *)view didChangeFocus:(CGPoint)focus {
    if(![self.session isRunning]) {
        return;
    }
    [self autoFocusAtPoint:focus];
}

@end
