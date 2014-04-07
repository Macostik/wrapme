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

@interface WLCameraViewController ()

@property (strong, nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) AVCaptureSession* session;
@property (nonatomic, strong) AVCaptureDeviceInput* frontFacingCameraDeviceInput;
@property (nonatomic, strong) AVCaptureDeviceInput* backFacingCameraDeviceInput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (weak, nonatomic) IBOutlet UIView *cameraView;

@property (strong, nonatomic) UIView* focusPointView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIImageView *acceptImageView;
@property (weak, nonatomic) IBOutlet UIView *acceptView;
@property (weak, nonatomic) IBOutlet UIView *acceptButtonsView;
@property (weak, nonatomic) IBOutlet UIButton *takePhotoButton;

@property (nonatomic) NSDictionary* metadata;

@end

@implementation WLCameraViewController

#pragma mark - View controller lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
    
	if (self.backfacingByDefault && self.backFacingCameraDeviceInput) {
		[self.session addInput:self.backFacingCameraDeviceInput];
	} else if (self.frontFacingCameraDeviceInput) {
		[self.session addInput:self.frontFacingCameraDeviceInput];
	}
    
    [self.session addOutput:[self stillImageOutput]];
    
    [self performSelector:@selector(start) withObject:nil afterDelay:0.0];
    
    self.flashMode = [[NSUserDefaults standardUserDefaults] integerForKey:@"WLCameraFlashMode"];
	
	if (self.mode == WLCameraModeFullSize) {
		self.topView.backgroundColor = [UIColor clearColor];
		self.bottomView.backgroundColor = [UIColor clearColor];
		self.cameraView.frame = self.view.bounds;
	}
	[self.cameraView.layer addSublayer:self.captureVideoPreviewLayer];
}

#pragma mark - User Actions

- (IBAction)cancel:(id)sender {
	if (self.delegate) {
		[self.delegate cameraViewControllerDidCancel:self];
	} else if (self.presentingViewController) {
		[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
	}
}

- (IBAction)shot:(id)sender {
	__weak typeof(self)weakSelf = self;
	[self captureImage:^(UIImage *image) {
		[weakSelf cropImage:image completion:^(UIImage *croppedImage) {
			[weakSelf setAcceptImage:croppedImage animated:YES];
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

- (AVCaptureDeviceInput*)deviceInputWithPosition:(AVCaptureDevicePosition)position {
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

- (AVCaptureSession *)session {
	if (!_session) {
		_session = [[AVCaptureSession alloc] init];
		if ([_session canSetSessionPreset:AVCaptureSessionPresetPhoto]) {
			_session.sessionPreset = AVCaptureSessionPresetPhoto;
		} else {
			_session.sessionPreset = AVCaptureSessionPresetMedium;
		}
	}
	return _session;
}

- (AVCaptureVideoPreviewLayer *)captureVideoPreviewLayer {
	if (!_captureVideoPreviewLayer) {
		_captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
		_captureVideoPreviewLayer.frame = self.cameraView.bounds;
		_captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	}
	return _captureVideoPreviewLayer;
}

- (AVCaptureDeviceInput *)frontFacingCameraDeviceInput {
	if (!_frontFacingCameraDeviceInput) {
		_frontFacingCameraDeviceInput = [self deviceInputWithPosition:AVCaptureDevicePositionFront];
	}
	return _frontFacingCameraDeviceInput;
}

- (AVCaptureDeviceInput *)backFacingCameraDeviceInput {
	if (!_backFacingCameraDeviceInput) {
		_backFacingCameraDeviceInput = [self deviceInputWithPosition:AVCaptureDevicePositionBack];
	}
	return _backFacingCameraDeviceInput;
}

- (AVCaptureStillImageOutput *)stillImageOutput {
	if (!_stillImageOutput) {
		_stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
		[_stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
	}
	return _stillImageOutput;
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

- (AVCaptureConnection*)videoConnection {
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in [self.stillImageOutput connections]) {
		for (AVCaptureInputPort *port in [connection inputPorts]) {
			if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
				videoConnection = connection;
                videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
				break;
			}
		}
		if (videoConnection) {
            break;
        }
	}
    return videoConnection;
}

- (void)captureImage:(void (^)(UIImage*image))completion {
	
#if TARGET_IPHONE_SIMULATOR
	if (self.mode == WLCameraModeFullSize) {
		completion([[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://placeimg.com/640/480/nature"]]]);
	} else {
		completion([[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://placeimg.com/640/640/nature"]]]);
	}
	return;
#endif
	
    AVCaptureConnection *videoConnection = [self videoConnection];
    videoConnection.videoMirrored = self.front;
	__weak typeof(self)weakSelf = self;
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection
                                                       completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
                                                           UIImage* image = nil;
                                                           if (!error) {
                                                               NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
                                                               image = [[UIImage alloc] initWithData:imageData];
															   weakSelf.metadata = (__bridge NSDictionary *)(CMCopyDictionaryOfAttachments(NULL, imageSampleBuffer, kCMAttachmentMode_ShouldPropagate));
                                                           }
                                                           completion(image);
                                                       }];
}

- (void)setFront:(BOOL)front {
    [self setFront:front animated:NO];
}

- (void)setFront:(BOOL)front animated:(BOOL)animated {
    [self setFront:front animated:animated completion:nil];
}

- (void)setFront:(BOOL)front animated:(BOOL)animated completion:(void (^)(void))completion {
    [UIView animateWithDuration:0.25f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.cameraView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        if (!self.frontFacingCameraDeviceInput) {
            completion();
            return;
        }
        [self.session beginConfiguration];
        if (front && [self.session.inputs containsObject:self.backFacingCameraDeviceInput]) {
            [self.session removeInput:self.backFacingCameraDeviceInput];
            [self.session addInput:self.frontFacingCameraDeviceInput];
        } else {
            [self.session removeInput:self.frontFacingCameraDeviceInput];
            [self.session addInput:self.backFacingCameraDeviceInput];
        }
        [self.session commitConfiguration];
        [UIView animateWithDuration:0.25f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.cameraView.alpha = 1.0f;
        } completion:^(BOOL finished) {
            if (completion) {
                completion();
            }
        }];
    }];

    [UIView transitionWithView:self.cameraView duration:0.5f options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionFlipFromLeft animations:^{
    } completion:^(BOOL finished) {
    }];
}

- (void)setFlashMode:(AVCaptureFlashMode)flashMode {
    if (self.front) {
        return;
    }
    
    if ([self.backFacingCameraDeviceInput.device isFlashModeSupported:flashMode]) {
        [self.session beginConfiguration];
        [self.backFacingCameraDeviceInput.device lockForConfiguration:nil];
        self.backFacingCameraDeviceInput.device.flashMode = flashMode;
        [self.backFacingCameraDeviceInput.device unlockForConfiguration];
        [self.session commitConfiguration];
        [[NSUserDefaults standardUserDefaults] setInteger:flashMode forKey:@"WLCameraFlashMode"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (AVCaptureFlashMode)flashMode {
    if (self.front) {
        return AVCaptureFlashModeOff;
    }
    return self.backFacingCameraDeviceInput.device.flashMode;
}

- (BOOL)front {
    return [self.session.inputs containsObject:self.frontFacingCameraDeviceInput];
}

- (BOOL)flashSupported {
    if (self.front) {
        return NO;
    } else {
        return [self.backFacingCameraDeviceInput.device isFlashModeSupported:AVCaptureFlashModeOn];
    }
}

- (void)setFocusPoint:(CGPoint)focusPoint {
    AVCaptureDeviceInput* input = self.front ? self.frontFacingCameraDeviceInput : self.backFacingCameraDeviceInput;
    
    if (input.device.focusPointOfInterestSupported && [input.device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        [self.session beginConfiguration];
        [input.device lockForConfiguration:nil];
        input.device.focusPointOfInterest = focusPoint;
        input.device.focusMode = AVCaptureFocusModeAutoFocus;
        [input.device unlockForConfiguration];
        [self.session commitConfiguration];
    }
}

- (CGPoint)focusPoint {
    AVCaptureDeviceInput* input = self.front ? self.frontFacingCameraDeviceInput : self.backFacingCameraDeviceInput;
    return input.device.focusPointOfInterest;
}

- (UIView *)focusPointView {
    if (!_focusPointView) {
        _focusPointView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 44.0f, 44.0f)];
        _focusPointView.layer.borderColor = [UIColor whiteColor].CGColor;
        _focusPointView.layer.borderWidth = 1.0f;
        [self.cameraView addSubview:self.focusPointView];
    }
    return _focusPointView;
}

- (void)animateFocusPoint:(CGPoint)viewPoint {
    self.focusPointView.center = viewPoint;
    
    self.focusPointView.alpha = 1.0f;
    
    [UIView animateWithDuration:0.5f delay:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.focusPointView.alpha = 0.0f;
    } completion:^(BOOL finished) {
    }];
}

- (void)setFocusPointFromViewPoint:(CGPoint)viewPoint {
    self.focusPoint = [self pointOfInterestFromPoint:viewPoint];
    [self animateFocusPoint:viewPoint];
}

- (CGPoint)pointOfInterestFromPoint:(CGPoint)point {
    CGSize frameSize = self.cameraView.frame.size;
    
    CGSize apertureSize = CMVideoFormatDescriptionGetCleanAperture([[self videoPort] formatDescription], YES).size;
    
    CGRect visibleRect = CGRectThatFitsSize(apertureSize, frameSize);
    
    point.x += visibleRect.origin.x;
    point.y += visibleRect.origin.y;
    
    if ([[self videoCaptureConnection] isVideoMirrored]) {
        point.x = frameSize.width - point.x;
    }
    
    return CGPointMake(point.x/apertureSize.width, point.y/apertureSize.height);
}

- (AVCaptureConnection *)videoCaptureConnection {
    for (AVCaptureConnection *connection in [self.stillImageOutput connections] ) {
		for ( AVCaptureInputPort *port in [connection inputPorts] ) {
			if ( [[port mediaType] isEqual:AVMediaTypeVideo] ) {
				return connection;
			}
		}
	}
    return nil;
}

- (AVCaptureInputPort*)videoPort {
    for (AVCaptureInputPort *port in [[self.session.inputs lastObject] ports]) {
        if ([port mediaType] == AVMediaTypeVideo) {
            return port;
        }
    }
    return nil;
}

@end
