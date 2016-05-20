//
//  DeviceManager.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/26/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import CoreMotion

class DeviceManager: BlockNotifier<UIDeviceOrientation> {
    
    static let defaultManager = DeviceManager()
    
    private var motionManager: CMMotionManager?
    
    override init() {
        super.init()
        UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
        NSNotificationCenter.defaultCenter().addObserverForName(UIDeviceOrientationDidChangeNotification, object: nil, queue: NSOperationQueue.mainQueue(), usingBlock: orientationChanged)
    }
    
    private var orientationFromAccelerometer: UIDeviceOrientation?
    
    var orientation: UIDeviceOrientation {
        if let orientation = orientationFromAccelerometer {
            return orientation
        } else {
            return UIDevice.currentDevice().orientation
        }
    }
    
    private func orientationChanged(notification: NSNotification) {
        orientationFromAccelerometer = nil
        notify(UIDevice.currentDevice().orientation)
    }
    
    func beginUsingAccelerometer() {
        let orientation = UIDevice.currentDevice().orientation
        if orientation != .Unknown {
            orientationFromAccelerometer = orientation
        }
        let motionManager = CMMotionManager()
        motionManager.accelerometerUpdateInterval = 0.5
        motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue(), withHandler: accelerationHandler)
        self.motionManager = motionManager
    }
    
    func accelerationHandler(accelerometerData: CMAccelerometerData?, error: NSError?) {
        guard let acceleration = accelerometerData?.acceleration else { return }
        var orientation: UIDeviceOrientation = .Portrait
        if (acceleration.x >= 0.75) {
            orientation = .LandscapeRight;
        } else if (acceleration.x <= -0.75) {
            orientation = .LandscapeLeft;
        } else if (acceleration.y <= -0.75) {
            orientation = .Portrait;
        } else if (acceleration.y >= 0.75) {
            orientation = .PortraitUpsideDown
        }
        if orientationFromAccelerometer != orientation {
            orientationFromAccelerometer = orientation
            Dispatch.mainQueue.async { _ in
                self.notify(orientation)
            }
        }
    }
    
    func endUsingAccelerometer() {
        motionManager?.stopAccelerometerUpdates()
        motionManager = nil
        orientationFromAccelerometer = nil
    }
}
