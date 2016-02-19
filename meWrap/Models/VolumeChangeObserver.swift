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
    var locked = false
    
    static let sharedObserver = VolumeChangeObserver()
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "outputVolume" {
            let value = change?[NSKeyValueChangeOldKey]
            changeVolumeValue(value != nil)
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    func registerWithBlock(success: Block) {
        initVolumeView()
        self.success = success
        defer {
            let center = NSNotificationCenter.defaultCenter()
            center.addObserver(self, selector: "sessionInterruption:", name: AVAudioSessionInterruptionNotification, object: nil)
            center.addObserver(self, selector: "activate:", name: UIApplicationDidBecomeActiveNotification, object: nil)
            audioSession.addObserver(self, forKeyPath: "outputVolume", options: [.New, .Old] , context:nil)
            changeVolumeValue(false)
        }
    }
    
    private func initVolumeView () {
        volumeView = MPVolumeView(frame: CGRectMake(CGFloat(MAXFLOAT), CGFloat(MAXFLOAT), 0, 0))
        guard let volumeView = volumeView else { return }
        _ = try? audioSession.setActive(true)
        UIWindow.mainWindow.addSubview(volumeView)
    }
    
    func unregister() {
        if volumeView != nil && success != nil {
            NSNotificationCenter.defaultCenter().removeObserver(self)
            audioSession.removeObserver(self, forKeyPath: "outputVolume", context: nil)
            success = nil
        }
        volumeView?.removeFromSuperview()
        locked = false
    }
    
    func sessionInterruption(notification: NSNotification) {
        if (notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt == 1) {
            initVolumeView()
        }
    }
    
    func activate(notification: NSNotification) {
        initVolumeView()
    }
    
    private func changeVolumeValue(change: Bool) {
        guard let subviews = volumeView?.subviews else { return }
        for subview in subviews {
            if let slider = subview as? UISlider {
                if change {
                    if (slider.value != 0.5) {
                        slider.value = 0.5
                        if !locked {
                            success?()
                        }
                    }
                } else {
                    Dispatch.mainQueue.after(1.0, block: { _ in
                        slider.value = 0.5
                    })
                }
                break
            }
        }
    }
}