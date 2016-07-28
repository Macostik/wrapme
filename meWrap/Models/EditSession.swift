//
//  EditSession.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/26/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

protocol EditSessionProtocol: class {
    var hasChanges: Bool { get set }
    func apply()
    func reset()
    func clean()
    weak var delegate: EditSessionDelegate? { get set }
}

protocol EditSessionDelegate: class {
    func editSession(session: EditSessionProtocol, hasChanges: Bool)
}

class EditSession<T: Equatable>: EditSessionProtocol {
    
    weak var delegate: EditSessionDelegate?
    
    var setter: (T -> Void)?
    
    var validator: (T -> Bool)?
    
    var originalValue: T {
        didSet {
            changedValue = originalValue
        }
    }
    
    var changedValue: T {
        didSet {
            hasChanges = changedValue != originalValue
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
        return validator?(changedValue) ?? true
    }
    
    func apply() {
        setter?(changedValue)
    }
    
    func reset() {
        setter?(originalValue)
    }
    
    func clean() {
        changedValue = originalValue
        hasChanges = false
    }
    
    init(originalValue: T, setter: (T -> Void)?, validator: (T -> Bool)? = nil) {
        self.setter = setter
        self.validator = validator
        self.originalValue = originalValue
        changedValue = originalValue
    }
}

class CompoundEditSession: EditSessionProtocol {
    
    private var sessions = [EditSessionProtocol]()
    
    func addSession(session: EditSessionProtocol) {
        session.delegate = self
        sessions.append(session)
    }
    
    weak var delegate: EditSessionDelegate?
    
    var hasChanges = false {
        didSet {
            if hasChanges != oldValue {
                delegate?.editSession(self, hasChanges: hasChanges)
            }
        }
    }
    
    func apply() {
        sessions.all({ $0.apply() })
    }
    
    func reset() {
        sessions.all({ $0.reset() })
    }
    
    func clean() {
        sessions.all({ $0.clean() })
    }
}

extension CompoundEditSession: EditSessionDelegate {
    
    func editSession(session: EditSessionProtocol, hasChanges: Bool) {
        self.hasChanges = hasChanges || sessions.contains({ $0.hasChanges })
    }
}

class ProfileEditSession: CompoundEditSession {
    
    var nameSession: EditSession<String>
    var emailSession: EditSession<String>
    var avatarSession: EditSession<String>
    
    required init(user: User) {
        nameSession = EditSession(originalValue: user.name ?? "", setter: { user.name = $0 })
        nameSession.validator = { return !$0.isEmpty }
        emailSession = EditSession(originalValue: Authorization.current.priorityEmail ?? "", setter: nil)
        emailSession.validator = { return !$0.isEmpty && $0.isValidEmail }
        avatarSession = EditSession(originalValue: user.avatar?.large ?? "", setter: { user.avatar?.large = $0 })
        avatarSession.validator = { return !$0.isEmpty }
        super.init()
        addSession(nameSession)
        addSession(emailSession)
        addSession(avatarSession)
    }
}
