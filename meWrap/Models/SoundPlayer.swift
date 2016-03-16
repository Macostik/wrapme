//
//  SoundPlayer.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/17/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import AudioToolbox

enum Sound: String {
    
    case s04 = "s04.wav"
    
    private static var IDs = [Sound : SystemSoundID]()
    
    func ID() -> SystemSoundID? {
        if let soundID = Sound.IDs[self] {
            return soundID
        } else if let url = NSBundle.mainBundle().URLForResource(rawValue, withExtension: nil) {
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
    
    private var currentSound: Sound?
    
    private var sounds = [Sound : SystemSoundID]()
    
    private var runQueue = RunQueue(limit: 1)
    
    func play(sound: Sound) {
        guard currentSound != sound else { return }
        guard UIApplication.sharedApplication().applicationState == .Active else { return }
        guard let soundID = sound.ID() else { return }
        runQueue.run { (finish) -> Void in
            self.currentSound = sound
            AudioServicesPlaySystemSound(soundID)
            Dispatch.mainQueue.after(3, block: { () -> Void in
                self.currentSound = nil
                finish()
            })
        }
    }
    
    class func playSend() {
        player.play(.s04)
    }
}
