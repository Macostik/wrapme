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
    
    private static var _currentUser: User?
    static var currentUser: User? {
        get {
            if _currentUser == nil {
                if let user = User.fetch().query("current == true").execute().first as? User {
                    _currentUser = user
                }
            }
            return _currentUser
        }
        set {
            _currentUser?.current = false
            _currentUser = newValue
            newValue?.current = true
        }
    }
    
    var isSignupCompleted: Bool { return name != nil && avatar?.medium != nil }
    
    var isInvited: Bool {
        if !current {
            if devices.count > 0 {
                for device in devices where device.activated {
                    return false
                }
                return true
            }
        }
        return false
    }
    
    private func formatPhones(secure: Bool) -> String? {
		var phones = ""
        for device in devices {
            guard let phone = device.phone else {
                continue
            }
            if !phones.isEmpty {
                phones += "\n"
            }
            if !current && secure && phone.characters.count > 4 {
                var _phone = ""
				for (index, character) in phone.characters.enumerate() {
                    if index >= phone.characters.count - 4 {
                        _phone = "\(_phone)\(character)"
                    } else {
                        _phone = "\(_phone)*"
                    }
				}
                phones += _phone
            } else {
                phones += phone
            }
        }
        return phones
    }
	
	private var _phones: String?
	var phones: String? {
        get {
            if _phones == nil {
                if let phones = formatPhones(false) {
                    _phones = phones
                } else {
                    _phones = "no_devices".ls
                }
            }
            return _phones
        }
        set { _phones = newValue }
    }
    
    private var _securePhones: String?
    var securePhones: String? {
        get {
            if _securePhones == nil {
                if let phones = formatPhones(true) {
                    _securePhones = phones
                } else {
                    _securePhones = "no_devices".ls
                }
            }
            return _securePhones
        }
        set {
            _securePhones = newValue
        }
    }
        
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
