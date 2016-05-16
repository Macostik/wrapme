//
//  APIRequest.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/17/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import Alamofire

extension API {
    
    static func signUp(authorization: Authorization) -> APIRequest<Authorization> {
        return APIRequest<Authorization>(.POST, "users", modifier: {
            $0.skipReauthorizing = true
            $0["device_uid"] = authorization.deviceUID
            $0["device_name"] = authorization.deviceName
            $0["country_calling_code"] = authorization.countryCode
            $0["phone_number"] = authorization.phone
            $0["email"] = authorization.email
            $0["device_token"] = NotificationCenter.defaultCenter.pushToken
            $0["os"] = "ios"
        }, parser: { _ in return authorization })
    }
    
    static func activation(authorization: Authorization) -> APIRequest<Authorization> {
        return APIRequest<Authorization>(.POST, "users/activate", modifier: {
            $0.skipReauthorizing = true
            $0["device_uid"] = authorization.deviceUID
            $0["device_name"] = authorization.deviceName
            $0["country_calling_code"] = authorization.countryCode
            $0["phone_number"] = authorization.phone
            $0["email"] = authorization.email
            $0["activation_code"] = authorization.activationCode
        }, parser: { response in
            authorization.password = response.dictionary("device")?["password"] as? String
            authorization.setCurrent()
            return authorization
        })
    }
    
    static func signIn(authorization: Authorization) -> APIRequest<User?> {
        return APIRequest<User?>(.POST, "users/sign_in", modifier: {
            $0.skipReauthorizing = true
            $0["device_uid"] = authorization.deviceUID
            $0["app_version"] = NSBundle.mainBundle().buildVersion
            $0["country_calling_code"] = authorization.countryCode
            $0["phone_number"] = authorization.phone
            $0["password"] = authorization.password
            $0["email"] = authorization.email
            $0.failureValidator = { (request, error) -> Bool in
                guard let error = error else { return true }
                guard let unconfirmed_email = authorization.unconfirmed_email where !unconfirmed_email.isEmpty else { return true }
                guard error.isResponseError(.NotFoundEntry) else { return true }
                guard (request["email"] as? String) != unconfirmed_email else { return true }
                request["email"] = unconfirmed_email
                request.enqueue()
                return false
            }
        }, parser: { response in
            
            if !Authorization.active {
                Authorization.active = true
                Uploader.wrapUploader.start()
            }
            
            let userDefaults = NSUserDefaults.standardUserDefaults()
            
            if let cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies {
                for cookie in cookies where cookie.name  == "_session_id" {
                    userDefaults.authorizationCookie = cookie
                }
            }
            
            
            userDefaults.pageSize = response["pagination_fetch_size"] as? Int ?? 30
            AssetURI.imageURI.remoteValue = response["image_uri"] as? String
            AssetURI.avatarURI.remoteValue = response["avatar_uri"] as? String
            AssetURI.videoURI.remoteValue = response["video_uri"] as? String
            AssetURI.mediaCommentURI.remoteValue = response["media_comment_uri"] as? String
            
            if let userData = response.dictionary("user"), let user: User = mappedEntry(userData) {
                userDefaults.remoteLogging = userData["remote_logging"] as? Bool ?? false
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
        })
    }
    
    static func updateDevice() -> APIRequest<AnyObject> {
        return APIRequest<AnyObject>(.PUT, "users/device", modifier: {
            $0.skipReauthorizing = true
            $0["device_token"] = NotificationCenter.defaultCenter.pushToken
            $0["os"] = "ios";
            $0["os_version"] = UIDevice.currentDevice().systemVersion
            $0["app_version"] = NSBundle.mainBundle().buildVersion
            let sourceFile = NSBundle.mainBundle().resourceURL?.URLByAppendingPathComponent("iTunesArtwork")
            if let date = sourceFile?.resource(NSURLContentModificationDateKey) as? NSDate {
                $0["installed_at"] = NSNumber(double: date.timestamp)
            }
        })
    }
    
    static func whois(email: String) -> APIRequest<WhoIs> {
        return APIRequest<WhoIs>(.GET, "users/whois", modifier: {
            $0.skipReauthorizing = true
            $0["email"] = email
            }, parser: { response in
            let whoIs = WhoIs.sharedInstance
            
            if let userInfo = response.dictionary("user") {
                whoIs.found = userInfo["found"] as? Bool ?? false
                whoIs.confirmed = userInfo["confirmed_email"] as? Bool ?? false
                if let user: User = User.entry(User.uid(userInfo)) {
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
    
    static func linkDevice(passcode: String) -> APIRequest<Authorization> {
        return APIRequest<Authorization>(.POST, "users/link_device", modifier: {
            $0.skipReauthorizing = true
            $0["email"] = Authorization.current.email
            $0["device_uid"] = Authorization.current.deviceUID
            $0["approval_code"] = passcode
        }, parser: { response in
            let authorization = Authorization.current
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
    
    func signUp() -> APIRequest<Authorization> { return API.signUp(self) }
    
    func activation() -> APIRequest<Authorization> { return API.activation(self) }
    
    func signIn() -> APIRequest<User?> { return API.signIn(self) }
}
