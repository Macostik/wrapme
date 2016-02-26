//
//  Camera.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/26/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import AVFoundation

extension AVCaptureSession {
    
    func configure( @noescape confirugation: AVCaptureSession -> Void) -> AVCaptureSession {
        beginConfiguration()
        confirugation(self)
        commitConfiguration()
        return self
    }
    
    func tryAddInput(input: AVCaptureDeviceInput?) {
        if let input = input where canAddInput(input) {
            addInput(input)
        }
    }
    
    func tryRemoveInput(input: AVCaptureDeviceInput?) {
        if let input = input {
            removeInput(input)
        }
    }
    
    func tryAddOutput(output: AVCaptureOutput?) {
        if let output = output where canAddOutput(output) {
            addOutput(output)
        }
    }
    
    func tryRemoveOutput(output: AVCaptureOutput?) {
        if let output = output {
            removeOutput(output)
        }
    }
}

class CaptureMediaSession: AVCaptureSession {
    
    override init() {
        super.init()
        if canSetSessionPreset(AVCaptureSessionPresetPhoto) {
            sessionPreset = AVCaptureSessionPresetPhoto
        } else {
            sessionPreset = AVCaptureSessionPresetMedium
        }
    }
    
    private var queue: dispatch_queue_t = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL)
    
    func performBlock(block: Void -> Void) {
        dispatch_async(queue, block)
    }
    
    func configure(confirugation: AVCaptureSession -> Void, completion: (Void -> Void)?) -> AVCaptureSession {
        performBlock { () -> Void in
            self.configure(confirugation)
            Dispatch.mainQueue.async(completion)
        }
        return self
    }
    
    func start() {
        dispatch_async(queue, {
            if !self.running {
                self.startRunning()
            }
        })
    }
    
    func stop() {
        dispatch_async(queue, {
            if self.running {
                self.stopRunning()
            }
        })
    }
    
    func containsOutput(output: AVCaptureOutput) -> Bool {
        return (outputs as! [AVCaptureOutput]).contains(output)
    }
}

extension AVCaptureDevice {
    
    class func microphone() -> AVCaptureDevice? {
        return devicesWithMediaType(AVMediaTypeAudio)?.first as? AVCaptureDevice
    }
    
    class func cameraWithPosition(position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        return cameras()?.filter({ $0.position == position }).first
    }
    
    class func cameras() -> [AVCaptureDevice]? {
        return devicesWithMediaType(AVMediaTypeVideo) as? [AVCaptureDevice]
    }
    
    func setSupportedFocusMode(focusMode: AVCaptureFocusMode) {
        if isFocusModeSupported(focusMode) {
            self.focusMode = focusMode
        }
    }
    
    func lock( @noescape confirugation: AVCaptureDevice -> Void) -> AVCaptureDevice {
        _ = try? lockForConfiguration()
        confirugation(self)
        unlockForConfiguration()
        return self
    }
    
    func input() -> AVCaptureDeviceInput? {
        return try? AVCaptureDeviceInput(device: self)
    }
    
    func autofocusingCameraInput() -> AVCaptureDeviceInput? {
        return try? AVCaptureDeviceInput(device: lock { $0.setSupportedFocusMode(.ContinuousAutoFocus) })
    }
    
    func focusOn(point: CGPoint) {
        if focusPointOfInterestSupported && isFocusModeSupported(.AutoFocus) {
            focusPointOfInterest = point
            focusMode = .AutoFocus
        }
    }
    
    func exposeOn(point: CGPoint) {
        if exposurePointOfInterestSupported && isExposureModeSupported(.AutoExpose) {
            exposurePointOfInterest = point
            exposureMode = .AutoExpose
        }
    }
    
    func concentrateOn(point: CGPoint) {
        focusOn(point)
        exposeOn(point)
    }
    
    func formatWithRatio(ratio: CGFloat) -> AVCaptureDeviceFormat? {
        for format in formats as! [AVCaptureDeviceFormat] {
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let _ratio = CGFloat(dimensions.width) / CGFloat(dimensions.height)
            if _ratio == ratio {
                return format
            }
        }
        return nil
    }
}

extension AVCaptureOutput {
    func videoConnection() -> AVCaptureConnection? {
        return connectionWithMediaType(AVMediaTypeVideo)
    }
}

extension AVCaptureConnection {
    func applyDeviceOrientation(orientation: UIDeviceOrientation) {
        if (orientation == .LandscapeLeft) {
            videoOrientation = .LandscapeRight
        } else if (orientation == .LandscapeRight) {
            videoOrientation = .LandscapeLeft;
        } else if (orientation == .PortraitUpsideDown) {
            videoOrientation = .PortraitUpsideDown
        } else {
            videoOrientation = .Portrait
        }
    }
}
