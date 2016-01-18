//
//  VolumeChangeObserver.swift
//  meWrap
//
//  Created by Yura Granchenko on 13/01/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import MediaPlayer

class VolumeChangeObserver : NSObject {
    
    let audioSession = AVAudioSession.sharedInstance()
    var success: Block?
    weak var volumeView: MPVolumeView?
    var context:UnsafeMutablePointer<Void>?
    private var lock = false
    
    static let sharedObserver = VolumeChangeObserver()
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == NSStringFromSelector("outputVolume") {
            let value = change![NSKeyValueChangeOldKey] as? Float
            changeVolumeValue(value != nil)
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    func registerChangeObserver(success: Block) {
        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(self, selector: "sessionInterruption:", name: AVAudioSessionInterruptionNotification, object: nil)
        center.addObserver(self, selector: "activate:", name: UIApplicationDidBecomeActiveNotification, object: nil)
        audioSession.addObserver(self, forKeyPath: NSStringFromSelector("outputVolume"), options: [.Initial, .New, .Old] , context:nil)
        self.success = success
        initVolumeView()
    }
    
    func initVolumeView () {
        volumeView = MPVolumeView(frame: CGRectMake(CGFloat(MAXFLOAT), CGFloat(MAXFLOAT), 0, 0))
        guard let volumeView = volumeView else { return }
        UIWindow.mainWindow.addSubview(volumeView)
        _ = try? audioSession.setActive(true)
    }
    
    func unregisterChagneObserver() {
        if volumeView != nil && success != nil {
            audioSession.removeObserver(self, forKeyPath: NSStringFromSelector("outputVolume"), context: nil)
        }
        volumeView?.removeFromSuperview()
        lock(false)
    }
    
    func sessionInterruption(notification: NSNotification) {
        if (notification.userInfo![AVAudioSessionInterruptionTypeKey] as? UInt == 1) {
           initVolumeView()
        }
    }
    
    func activate (notification: NSNotification) {
        initVolumeView()
    }
    
    func changeVolumeValue(change: Bool) {
        if (lock) { return }
        var i = 0
        while i < volumeView?.subviews.count {
            if let slider = volumeView?.subviews[i] as? UISlider {
                if (change) {
                if (slider.value != 0.5) {
                    slider.value = 0.5
                        self.success?()
                    }
                } else {
                    Dispatch.mainQueue.after(0.1, block: { _ in
                        slider.value = 0.5
                    })
                }
                break
            }
            ++i
        }
    }
    
    func lock(lock: Bool) {
        self.lock = lock
    }
}