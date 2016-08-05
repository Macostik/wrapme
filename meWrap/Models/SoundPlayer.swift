//
//  SoundPlayer.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/17/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import AudioToolbox
import AVFoundation

struct AudioSession {
    
    static var category: String {
        get { return AVAudioSession.sharedInstance().category }
        set {
            _ = try? AVAudioSession.sharedInstance().setCategory(newValue)
            _ = try? AVAudioSession.sharedInstance().setActive(true)
        }
    }
    
    static var mode: String {
        get { return AVAudioSession.sharedInstance().mode }
        set {
            _ = try? AVAudioSession.sharedInstance().setMode(newValue)
            _ = try? AVAudioSession.sharedInstance().setActive(true)
        }
    }
}

enum Sound: String {
    
    case s04 = "s04.wav"
    case note = "note.wav"
    
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
    
    static func play(sound: Sound = .s04) {
        guard UIApplication.isActive else { return }
        guard let soundID = sound.ID() else { return }
        AudioServicesPlaySystemSound(soundID)
    }
}
