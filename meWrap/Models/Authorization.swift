//
//  Authorization.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/26/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

final class Authorization: Archive {
    
    static var active: Bool = {
        if let cookie = NSUserDefaults.standardUserDefaults().authorizationCookie {
            NSHTTPCookieStorage.sharedHTTPCookieStorage().setCookie(cookie)
            return true
        } else {
            return false
        }
    }()
    
    class func requiresSignIn() -> Bool {
        let defaults = NSUserDefaults.standardUserDefaults()
        guard active else { return true }
        guard defaults.remoteLogging != nil else { return true }
        guard AssetURI.imageURI.remoteValue != nil else { return true }
        guard AssetURI.avatarURI.remoteValue != nil else { return true }
        guard AssetURI.videoURI.remoteValue != nil else { return true }
        guard AssetURI.mediaCommentURI.remoteValue != nil else { return true }
        guard User.currentUser?.uid != nil else { return true }
        return false
    }
    
    override class func archivableProperties() -> Set<String> {
        return ["deviceUID","deviceName","countryCode","phone","email","unconfirmed_email","password"]
    }
    
    lazy var deviceUID: String = DeviceManager.defaultManager.UDID
    
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
        return canSignUp && !(password?.isEmpty ?? true)
    }
    
    func updateWithUserData(userData: [String : AnyObject]) {
        if let email = userData[Keys.Email] as? String {
            self.email = email
        }
        self.unconfirmed_email = userData[Keys.UnconfirmedEmail] as? String ?? ""
        setCurrent()
    }
    
    static var current: Authorization {
        get { return NSUserDefaults.standardUserDefaults().authorization ?? Authorization() }
        set { NSUserDefaults.standardUserDefaults().authorization = newValue }
    }
    
    var priorityEmail: String? {
        if let unconfirmed_email = unconfirmed_email where !unconfirmed_email.isEmpty {
            return unconfirmed_email
        } else {
            return email
        }
    }
    
    func setCurrent() {
        Authorization.current = self
    }
}
