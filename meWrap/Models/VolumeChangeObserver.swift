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
        if let oldValue = change?[NSKeyValueChangeOldKey] as? Float where !(initialization && AVAudioSession.sharedInstance().outputVolume == 0.5) {
            didChangeVolume(oldValue)
        }
    }
    
    func registerWithBlock(success: Block) {
        initVolumeView()
        self.success = success
        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(self, selector: #selector(self.activate(_:)), name: UIApplicationDidBecomeActiveNotification, object: nil)
        audioSession.addObserver(self, forKeyPath: "outputVolume", options: [.New, .Old] , context:nil)
    }
    
    private func initVolumeView () {
        self.volumeView?.removeFromSuperview()
        let volumeView = MPVolumeView(frame: CGRectMake(CGFloat(MAXFLOAT), CGFloat(MAXFLOAT), 0.5, 0.5))
        UIWindow.mainWindow.addSubview(volumeView)
        _ = try? audioSession.setActive(true)
        self.volumeView = volumeView
        initialization = true
        Dispatch.mainQueue.after(0.5) { () in
            self.setVolumeIfNeeded()
        }
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
    
    func activate(notification: NSNotification) {
        initVolumeView()
    }
    
    private var initialization = false
    
    private func setVolumeIfNeeded() {
        let volume = AVAudioSession.sharedInstance().outputVolume
        if volume == 0 || volume == 1 {
            volumeView?.volumeSlider()?.value = 0.5
            Dispatch.mainQueue.after(0.5) { () in
                self.initialization = false
            }
        } else {
            initialization = false
        }
    }
    
    private func didChangeVolume(oldValue: Float) {
        if let slider = volumeView?.volumeSlider() {
            if (slider.value != oldValue) {
                slider.value = oldValue
                if !locked {
                    success?()
                }
            }
        }
    }
}

extension MPVolumeView {
    
    private func volumeSlider() -> UISlider? {
        for subview in subviews {
            if let slider = subview as? UISlider {
                slider.continuous = false
                return slider
            }
        }
        return nil
    }
}