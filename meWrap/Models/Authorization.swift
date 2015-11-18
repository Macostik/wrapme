//
//  Authorization.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/26/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import OpenUDID

class Authorization: Archive {
    
    override class func archivableProperties() -> Set<String> {
        return ["deviceUID","deviceName","countryCode","phone","email","unconfirmed_email","password"]
    }
    
    var deviceUID: String? = OpenUDID.value()
    
    var deviceName: String = UIDevice.currentDevice().modelName()
    
    var countryCode: String?
    
    var phone: String?
    
    var formattedPhone: String?
    
    var email: String?
    
    var unconfirmed_email: String?
    
    var activationCode: String?
    
    var password: String?
    
    var fullPhoneNumber: String {
        return "+\(countryCode ?? "") \(formattedPhone ?? phone ?? "")"
    }
    
    var canSignUp: Bool {
        return !(email?.isEmpty ?? true)
    }
    
    var canAuthorize: Bool {
        return canSignUp && !(email?.isEmpty ?? true)
    }
    
    func updateWithUserData(userData: Dictionary<String, AnyObject>) {
        if let email = userData[WLEmailKey] as? String {
            self.email = email
        }
        if let unconfirmed_email = userData[WLUnconfirmedEmail] as? String {
            self.unconfirmed_email = unconfirmed_email
        }
        setCurrent()
    }
    
    static var currentAuthorization: Authorization {
        get {
            if let authorization = NSUserDefaults.standardUserDefaults().authorization {
                return authorization
            } else {
                return Authorization()
            }
        }
        set {
            NSUserDefaults.standardUserDefaults().authorization = newValue
        }
    }
    
    var priorityEmail: String? {
        if let unconfirmed_email = unconfirmed_email where unconfirmed_email.nonempty {
            return unconfirmed_email
        } else {
            return email
        }
    }
    
    func setCurrent() {
        Authorization.currentAuthorization = self
    }
}
