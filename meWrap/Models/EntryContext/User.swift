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
    
    static var currentUser: User? = User.fetch().query("current == true").execute().first as? User {
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
    
    lazy var activity: UserActivity = UserActivity(user: self)
    
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
