//
//  SoundPlayer.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/17/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import AudioToolbox

@objc enum Sound: Int {
    
    case Off, s01, s02, s03, s04
    
    func fileName() -> String? {
        switch self {
        case .s01: return "s01.wav"
        case .s02: return "s02.wav"
        case .s03: return "s03.wav"
        case .s04: return "s04.wav"
        default: return nil
        }
    }
    
    private static var IDs = [Sound : SystemSoundID]()
    
    func ID() -> SystemSoundID? {
        if let soundID = Sound.IDs[self] {
            return soundID
        } else if let url = NSBundle.mainBundle().URLForResource(fileName(), withExtension: nil) {
            var soundID: SystemSoundID = 0
            AudioServicesCreateSystemSoundID(url, &soundID)
            Sound.IDs[self] = soundID
            return soundID
        } else {
            return nil
        }
    }
}

class SoundPlayer: NSObject {
    
    static let player = SoundPlayer()
    
    private var currentSound = Sound.Off
    
    private var sounds = [Sound : SystemSoundID]()
    
    private var runQueue = RunQueue(limit: 1)
    
    func play(sound: Sound) {
        guard sound != .Off else { return }
        guard currentSound != sound else { return }
        guard UIApplication.sharedApplication().applicationState == .Active else { return }
        guard let soundID = sound.ID() else { return }
        if currentSound == .Off {
            currentSound = sound
        }
        runQueue.run { (finish) -> Void in
            self.currentSound = sound
            AudioServicesPlaySystemSound(soundID)
            Dispatch.mainQueue.after(3, block: { () -> Void in
                self.currentSound = .Off
                finish()
            })
        }
    }
}

extension SoundPlayer {
    func playForNotification(notification: Notification) {
        if notification.playSound() {
            play(notification.soundType())
        }
    }
}
