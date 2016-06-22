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
    
    static var category: String? {
        didSet {
            if let category = category where category != oldValue {
                _ = try? AVAudioSession.sharedInstance().setCategory(category)
                _ = try? AVAudioSession.sharedInstance().setActive(true)
            }
        }
    }
    
    static var mode: String? {
        didSet {
            if let mode = mode where mode != oldValue {
                _ = try? AVAudioSession.sharedInstance().setMode(mode)
            }
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
