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
    var volumeView: MPVolumeView?
    var context: UnsafeMutablePointer<Void>?
    
    static var sharedObserver: VolumeChangeObserver = {
        let volumeChangeObserver = VolumeChangeObserver()
        do {
            try volumeChangeObserver.audioSession.setActive(true)
        } catch {}
        return volumeChangeObserver
    }()
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "outputVolume" {
            self.context = context
            success?()
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    func registerChangeObserver(success: Block) {
        self.success = success
        audioSession.addObserver(self, forKeyPath: "outputVolume", options: [.New] , context: nil)
        volumeView = MPVolumeView()
        guard let volumeView = volumeView else { return }
        let window = UIWindow.mainWindow
        window.addSubview(volumeView)
        volumeView.layer.transform = CATransform3DMakeTranslation(0, -window.frame.height, 0)
    }
    
    func unregisterChagneObserver() {
        volumeView?.removeFromSuperview()
        if var context = context {
            audioSession.removeObserver(self, forKeyPath: "outputVolume", context: context)
            context = nil
        }
    }
}