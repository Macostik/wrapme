//
//  APIRequest.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/17/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

extension APIRequest {
    
    class func APIRequest(method: APIRequestMethod) -> Self {
        let request = self.init(method)
        request.skipReauthorizing = true
        return request
    }
    
    class func signUp(authorization: Authorization) -> Self {
        return APIRequest(.POST).path("users").parametrize({ (request) -> Void in
            request["device_uid"] = authorization.deviceUID
            request["device_name"] = authorization.deviceName
            request["country_calling_code"] = authorization.countryCode
            request["phone_number"] = authorization.phone
            request["email"] = authorization.email
            request["device_token"] = WLNotificationCenter.defaultCenter().pushTokenString
            request["os"] = "ios"
        }).parse({ (_) -> AnyObject? in return authorization })
    }
    
    class func activation(authorization: Authorization) -> Self {
        return APIRequest(.POST).path("users/activate").parametrize({ (request) -> Void in
            request["device_uid"] = authorization.deviceUID
            request["device_name"] = authorization.deviceName
            request["country_calling_code"] = authorization.countryCode
            request["phone_number"] = authorization.phone
            request["email"] = authorization.email
            request["activation_code"] = authorization.activationCode
        }).parse { (response) -> AnyObject? in
            authorization.password = response.dictionary("device")?["password"] as? String
            authorization.setCurrent()
            return authorization
        }
    }
    
    class func signIn(authorization: Authorization) -> Self {
        return APIRequest(.POST).path("users/sign_in").parametrize({ (request) -> Void in
            request["device_uid"] = authorization.deviceUID
            request["app_version"] = NSBundle.mainBundle().buildVersion
            request["country_calling_code"] = authorization.countryCode
            request["phone_number"] = authorization.phone
            request["password"] = authorization.password
            request["email"] = authorization.email
        }).parse({ (response) -> AnyObject? in
            
            if !Authorization.active {
                Authorization.active = true
                WLUploadingQueue.start()
            }
            
            let environment = Environment.currentEnvironment
            let userDefaults = NSUserDefaults.standardUserDefaults()
            
            if let cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies {
                for cookie in cookies where cookie.name  == "_session_id" {
                    userDefaults.authorizationCookie = cookie
                }
            }
            
            userDefaults.remoteLogging = response["remote_logging"] as? Bool ?? false
            userDefaults.pageSize = response["pagination_fetch_size"] as? Int ?? 30
            userDefaults.imageURI = response["image_uri"] as? String ?? environment.defaultImageURI
            userDefaults.avatarURI = response["avatar_uri"] as? String ?? environment.defaultAvatarURI
            userDefaults.videoURI = response["video_uri"] as? String ?? environment.defaultVideoURI
            
            if let userData = response.dictionary("user"), let user = User.mappedEntry(userData) {
                authorization.updateWithUserData(userData)
                User.currentUser = user
                user.notifyOnAddition()
                
                if user.firstTimeUse {
                    user.preloadFirstWraps()
                }
                
                return user
            } else {
                return nil
            }
        }).validateFailure({ (request, error) -> Bool in
            guard let error = error else { return true }
            guard let unconfirmed_email = authorization.unconfirmed_email else { return true }
            guard error.isResponseError(.NotFoundEntry) else { return true }
            guard (request["email"] as? String) != unconfirmed_email else { return true }
            request["email"] = unconfirmed_email
            request.enqueue()
            return false
        })
    }
    
    class func updateDevice() -> Self {
        return APIRequest(.PUT).path("users/device").parametrize({ (request) -> Void in
            request["device_token"] = WLNotificationCenter.defaultCenter().pushTokenString
            request["os"] = "ios";
            request["os_version"] = UIDevice.currentDevice().systemVersion
            request["app_version"] = NSBundle.mainBundle().buildVersion
            let sourceFile = NSBundle.mainBundle().resourceURL?.URLByAppendingPathComponent("iTunesArtwork")
            if let date = sourceFile?.resource(NSURLContentModificationDateKey) as? NSDate {
                request["installed_at"] = NSNumber(double: date.timestamp)
            }
        })
    }
    
    class func whois(email: String) -> Self {
        return APIRequest(.GET).path("users/whois").parametrize({ $0["email"] = email }).parse({ (response) -> AnyObject? in
            let whoIs = WhoIs.sharedInstance
            
            if let userInfo = response.dictionary("user") {
                whoIs.found = userInfo["found"] as? Bool ?? false
                whoIs.confirmed = userInfo["confirmed_email"] as? Bool ?? false
                if let user = User.entry(User.uid(userInfo)) {
                    User.currentUser = user
                    user.notifyOnAddition()
                }
                
                let authorization = Authorization()
                authorization.email = email
                if !whoIs.confirmed {
                    authorization.unconfirmed_email = email
                }
                authorization.setCurrent()
                let deviceUID = authorization.deviceUID
                if let devices = userInfo["device_uids"] as? [[String:String]] {
                    if devices.count == 0 || (devices.count == 1 && devices[0]["device_uid"] == deviceUID) {
                        whoIs.requiresApproving = false
                    } else {
                        whoIs.requiresApproving = true
                        whoIs.containsPhoneDevice = false
                        for device in devices {
                            if let phone = device["full_phone_number"] where device["device_uid"] != deviceUID && !phone.isEmpty {
                                whoIs.containsPhoneDevice = true
                                break
                            }
                        }
                    }
                }
            }
            return whoIs
        })
    }
    
    class func linkDevice(passcode: String) -> Self {
        return APIRequest(.POST).path("users/link_device").parametrize({ (request) -> Void in
            request["email"] = Authorization.currentAuthorization.email
            request["device_uid"] = Authorization.currentAuthorization.deviceUID
            request["approval_code"] = passcode
        }).parse({ (response) -> AnyObject? in
            let authorization = Authorization.currentAuthorization
            authorization.password = response.dictionary("device")?["password"] as? String
            authorization.setCurrent()
            return authorization
        })
    }
}

class WhoIs: NSObject {
    static var sharedInstance = WhoIs()
    var found = false
    var confirmed = false
    var requiresApproving = false
    var containsPhoneDevice = false
}

extension Authorization {
    
    func signUp() -> APIRequest { return APIRequest.signUp(self) }
    
    func activation() -> APIRequest { return APIRequest.activation(self) }
    
    func signIn() -> APIRequest { return APIRequest.signIn(self) }
}
