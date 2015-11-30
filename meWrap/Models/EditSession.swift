//
//  EditSession.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/26/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

@objc protocol EditSessionDelegate {
    func editSession(session: EditSession, hasChanges: Bool)
}

class EditSession: NSObject {
    
    deinit {
        print("EditSession dealloc")
    }
    
    weak var delegate: EditSessionDelegate?
    
    var setter: ((EditSession, NSObject?) -> Void)?
    
    var validator: ((EditSession, NSObject?) -> Bool)?
    
    var originalValue: NSObject?
    
    var changedValue: NSObject? {
        didSet {
            hasChanges = !(changedValue == originalValue)
        }
    }
    
    var hasChanges = false {
        didSet {
            if hasChanges != oldValue {
                delegate?.editSession(self, hasChanges: hasChanges)
            }
        }
    }
    
    var hasValidChanges: Bool {
        return validator?(self, changedValue) ?? true
    }
    
    func apply() {
        setter?(self, changedValue)
    }
    
    func reset() {
        setter?(self, originalValue)
    }
    
    func clean() {
        changedValue = originalValue
        hasChanges = false
    }
    
    convenience init(originalValue: NSObject?, setter: ((EditSession, NSObject?) -> Void)?) {
        self.init(originalValue: originalValue, setter: setter, validator: nil)
    }
    
    convenience init(originalValue: NSObject?, setter: ((EditSession, NSObject?) -> Void)?, validator: ((EditSession, NSObject?) -> Bool)?) {
        self.init()
        self.setter = setter
        self.validator = validator
        self.originalValue = originalValue
        changedValue = originalValue
    }
}

class CompoundEditSession: EditSession {
    
    private var sessions = [EditSession]()
    
    func addSession(session: EditSession) {
        session.delegate = self
        sessions.append(session)
    }
    
    override func apply() {
        for session in sessions {
            session.apply()
        }
    }
    
    override func reset() {
        for session in sessions {
            session.reset()
        }
    }
    
    override func clean() {
        for session in sessions {
            session.clean()
        }
    }
}

extension CompoundEditSession: EditSessionDelegate {
    func editSession(session: EditSession, hasChanges: Bool) {
        self.hasChanges = hasChanges || sessions.contains({ $0.hasChanges })
    }
}

class ProfileEditSession: CompoundEditSession {
    
    var nameSession: EditSession
    var emailSession: EditSession
    var avatarSession: EditSession
    
    required init(user: User) {
        nameSession = EditSession(originalValue: user.name, setter: { [weak user] (session, value) -> Void in
            user?.name = (value as? String)
            }, validator: { (session, value) -> Bool in
                return (value as? NSString)?.nonempty ?? false
        })
        emailSession = EditSession(originalValue: Authorization.currentAuthorization.priorityEmail, setter: nil, validator: { (session, value) -> Bool in
            if let email = value as? NSString {
                return email.nonempty && email.isValidEmail
            } else {
                return false
            }
        })
        avatarSession = EditSession(originalValue: user.picture?.large, setter: { [weak user] (session, value) -> Void in
            user?.picture?.large = (value as? String)
            }, validator: { (session, value) -> Bool in
                return (value as? NSString)?.nonempty ?? false
        })
        super.init()
        addSession(nameSession)
        addSession(emailSession)
        addSession(avatarSession)
    }
}
