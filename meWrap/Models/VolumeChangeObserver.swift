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
    
    static var sharedObserver: VolumeChangeObserver = {
        let volumeChangeObserver = VolumeChangeObserver()
        _ = try? volumeChangeObserver.audioSession.setActive(true)
        return volumeChangeObserver
    }()
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == NSStringFromSelector("outputVolume") {
            let value = change![NSKeyValueChangeOldKey] as? Float
            changeVolumeValue(value != nil)
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    func registerChangeObserver(success: Block) {
        self.success = success
        audioSession.addObserver(self, forKeyPath: NSStringFromSelector("outputVolume"), options: [.Initial, .New, .Old] , context:nil)
        volumeView = MPVolumeView()
        guard let volumeView = volumeView else { return }
        let window = UIWindow.mainWindow
        window.addSubview(volumeView)
        volumeView.layer.transform = CATransform3DMakeTranslation(0, -window.frame.height, 0)
    }
    
    func unregisterChagneObserver() {
        if volumeView != nil && success != nil {
            audioSession.removeObserver(self, forKeyPath: NSStringFromSelector("outputVolume"), context: nil)
        }
        volumeView?.removeFromSuperview()
        lock(false)
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
                    slider.value = 0.5
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