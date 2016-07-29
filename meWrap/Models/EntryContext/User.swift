//
//  User.swift
//
//
//  Created by Sergey Maximenko on 10/26/15.
//
//

import Foundation
import CoreData

@objc(User)
final class User: Entry, Contributor {
    
    override class func entityName() -> String { return "User" }
    
    static var currentUser: User? = FetchRequest<User>().query("current == true").execute().first {
        didSet {
            oldValue?.current = false
            currentUser?.current = true
        }
    }
    
    var signupPending: Bool {
        return !current && devices.count > 0 && !devices.contains({ $0.activated })
    }
    
    var isOnline: Bool = false {
        didSet {
            if isOnline != oldValue {
                self.notifyOnUpdate(.UserStatus)
            }
        }
    }
    
    var devicesOnline = Set<Device>() {
        didSet {
            isOnline = devicesOnline.count > 0
        }
    }
    
    func activityForWrap(wrap: Wrap) -> UserActivity? {
        guard !devicesOnline.isEmpty else { return nil }
        return devicesOnline.sort({ $0.activeAt > $1.activeAt })[{ $0.activity.wrap == wrap && $0.activity.inProgress }]?.activity
    }
    
    var activeAt: NSDate {
        return devices.map{ $0.activeAt }.maxElement() ?? NSDate(timeIntervalSince1970: 0)
    }
    
    private func formatPhones(secure: Bool) -> String {
        let hiddenCharacter: Character = "*"
        let phones = devices.reduce("", combine: { (phones, device) -> String in
            guard let phone = device.phone else { return phones }
            let count = phone.characters.count
            if !current && secure && count > 4 {
                let hiddenPart = String(count: count - 4, repeatedValue: hiddenCharacter)
                return phones + (phones.isEmpty ? "" : "\n") + hiddenPart + phone.substringFromIndex(phone.endIndex.advancedBy(-4))
            } else {
                return phones + (phones.isEmpty ? "" : "\n") + phone
            }
        })
        return phones.isEmpty ? "no_devices".ls : phones
    }
    
    lazy var phones: String = self.formatPhones(false)
    
    lazy var securePhones: String = self.formatPhones(true)
    
    var sortedWraps: [Wrap] {
        return wraps.sort({ $0.updatedAt > $1.updatedAt })
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        if avatar == nil {
            avatar = Asset()
        }
    }
    
    var displayName: String? {
        return name
    }
    
    func contributorInfo() -> String {
        if signupPending {
            let invitedAt = self.invitedAt.stringWithDateStyle(.ShortStyle)
            return "sign_up_pending".ls + "\n" + String(format: "invite_status_swipe_to".ls, invitedAt) + "\n\(securePhones)"
        } else {
            return "signup_status".ls + "\n\(securePhones)"
        }
    }
    
    var p2pWrap: Wrap? {
        return User.currentUser?.wraps[{ $0.p2p && $0.contributors.contains(self) }]
    }
}

@objc(Device)
final class Device: Entry {
    
    var activeAt: NSDate = NSDate(timeIntervalSince1970: 0)
    
    var isOnline: Bool = false {
        didSet {
            if isOnline != oldValue {
                if isOnline {
                    owner?.devicesOnline.insert(self)
                } else {
                    owner?.devicesOnline.remove(self)
                }
            }
        }
    }
    
    lazy var activity: UserActivity = UserActivity(device: self)
    
    func activityForWrap(wrap: Wrap) -> UserActivity? {
        return (activity.wrap == wrap && activity.inProgress) ? activity : nil
    }
    
    override class func entityName() -> String { return "Device" }
    
    override var container: Entry? {
        get { return owner }
        set {
            if let owner = newValue as? User {
                self.owner = owner
            }
        }
    }
    
    var current: Bool {
        return uid == Authorization.current.deviceUID
    }
}
