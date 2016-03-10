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
class User: Entry {

    override class func entityName() -> String { return "User" }
    
    static var currentUser: User? = FetchRequest<User>("current == true").execute().first {
        didSet {
            oldValue?.current = false
            currentUser?.current = true
        }
    }
    
    var isSignupCompleted: Bool { return name != nil }
    
    var isInvited: Bool {
        return !current && devices.count > 0 && !devices.contains({ $0.activated })
    }
    
    var isActive: Bool = false {
        didSet {
            if isActive != oldValue {
                self.notifyOnUpdate(.UserStatus)
            }
        }
    }
    
    var numberOfActiveDevices: Int = 0 {
        didSet {
            if numberOfActiveDevices != oldValue {
                isActive = numberOfActiveDevices > 0
            }
        }
    }
    
    func activityForWrap(wrap: Wrap) -> UserActivity? {
        let device = devices.sort({ $0.activeAt > $1.activeAt })[{ $0.activity.wrap == wrap && $0.activity.inProgress }]
        return device?.activity
    }
    
    func isActiveInWrap(wrap: Wrap) -> Bool {
        return activityForWrap(wrap) != nil
    }
    
    func isActiveInWrap(wrap: Wrap, type: UserActivityType) -> Bool {
        return activityForWrap(wrap)?.type == type
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
	
	lazy var phones: String? = self.formatPhones(false)
    
    lazy var securePhones: String? = self.formatPhones(true)
        
    var sortedWraps: [Wrap]? {
        return wraps.sort({ $0.updatedAt > $1.updatedAt })
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        if avatar == nil {
            avatar = Asset()
        }
    }
}

@objc(Device)
class Device: Entry {
    
    var activeAt: NSDate = NSDate(timeIntervalSince1970: 0)
    
    var isActive: Bool = false {
        didSet {
            if isActive != oldValue {
                if isActive {
                    owner?.numberOfActiveDevices++
                } else {
                    owner?.numberOfActiveDevices--
                }
            }
        }
    }
    
    lazy var activity: UserActivity = UserActivity(device: self)
    
    func activityForWrap(wrap: Wrap) -> UserActivity? {
        return (activity.wrap == wrap && activity.inProgress) ? activity : nil
    }
    
    func isActiveInWrap(wrap: Wrap) -> Bool {
        return activityForWrap(wrap) != nil
    }
    
    func isActiveInWrap(wrap: Wrap, type: UserActivityType) -> Bool {
        return activityForWrap(wrap)?.type == type
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
}
