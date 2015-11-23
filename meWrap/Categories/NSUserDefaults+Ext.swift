//
//  NSUserDefaults+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/29/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

private var _authorization: Authorization?
private var _confirmationDate: NSDate?
private var _historyDate: NSDate?
private var _handledNotifications: NSOrderedSet?
private var _imageURI: String?
private var _videoURI: String?
private var _avatarURI: String?
private var _pageSize: Int = -1

extension NSUserDefaults {
    
    // MARK: - defined fields
    
    var authorization: Authorization? {
        get {
            if _authorization == nil {
                if let data = NSUserDefaults.sharedUserDefaults?["encrypted_authorization"] as? NSData {
                    _authorization = Authorization.unarchive(WLCryptographer.decryptData(data)) as? Authorization
                } else if let data = self["WrapLiveAuthorization"] as? NSData {
                    _authorization = Authorization.unarchive(data) as? Authorization
                }
            }
            return _authorization
        }
        set {
            _authorization = newValue
            guard let sharedUserDefaults = NSUserDefaults.sharedUserDefaults else {
                return
            }
            if let authorization = newValue, let data = authorization.archive(), let encryptedData = WLCryptographer.encryptData(data) {
                self["WrapLiveAuthorization"] = data
                sharedUserDefaults["encrypted_authorization"] = encryptedData
            } else {
                self["WrapLiveAuthorization"] = nil
                sharedUserDefaults["encrypted_authorization"] = nil
            }
        }
    }
    
    var authorizationCookie: NSHTTPCookie? {
        get {
            if let properties = self["authorizationCookie"] as? [String : AnyObject] {
                return NSHTTPCookie(properties: properties)
            } else {
                return nil
            }
        }
        set {
            self["authorizationCookie"] = newValue?.properties
        }
    }
    
    var confirmationDate: NSDate? {
        get {
            if _confirmationDate == nil {
                _confirmationDate = self["WLSessionConfirmationConditions"] as? NSDate
            }
            return _confirmationDate
        }
        set {
            _confirmationDate = newValue
            self["WLSessionConfirmationConditions"] = newValue
        }
    }
    
    var appVersion: String? {
        get {
            return self["wrapLiveVersion"] as? String
        }
        set {
            self["wrapLiveVersion"] = newValue
        }
    }
    
    var numberOfLaunches: Int {
        get {
            return (self["WLNumberOfLaucnhes"] as? Int) ?? 0
        }
        set {
            self["WLNumberOfLaucnhes"] = newValue
        }
    }
    
    var cameraDefaultPosition: NSNumber? {
        get {
            return self["WLCameraDefaultPosition"] as? Int
        }
        set {
            self["WLCameraDefaultPosition"] = newValue
        }
    }
    
    var cameraDefaultFlashMode: NSNumber? {
        get {
            return self["WLCameraDefaultFlashMode"] as? Int
        }
        set {
            self["WLCameraDefaultFlashMode"] = newValue
        }
    }
    
    var shownHints: NSMutableDictionary {
        get {
            if let shownHints = self["WLHintView_shownHints"] as? NSDictionary {
                return shownHints.mutableCopy() as! NSMutableDictionary
            } else {
                let shownHints = NSMutableDictionary()
                self["WLHintView_shownHints"] = shownHints
                return shownHints
            }
        }
        set {
            self["WLHintView_shownHints"] = newValue
        }
    }
    
    var historyDate: NSDate? {
        get {
            if _historyDate == nil {
                _historyDate = self["historyDate"] as? NSDate
            }
            return _historyDate
        }
        set {
            _historyDate = newValue
            self["historyDate"] = newValue
        }
    }
    
    var handledNotifications: NSOrderedSet? {
        get {
            if _handledNotifications == nil {
                if let array = self["handledNotifications"] as? [AnyObject] {
                    _handledNotifications = NSOrderedSet(array: array)
                } else {
                    _handledNotifications = NSOrderedSet()
                }
            }
            return _handledNotifications
        }
        set {
            _handledNotifications = newValue
            self["handledNotifications"] = newValue?.array
        }
    }
    
    var recentEmojis: [String]? {
        get {
            return self["recentEmojis"] as? [String]
        }
        set {
            self["recentEmojis"] = newValue
        }
    }
    
    var imageURI: String? {
        get {
            if _imageURI == nil {
                _imageURI = self["imageURI"] as? String
            }
            return _imageURI
        }
        set {
            _imageURI = newValue
            self["imageURI"] = newValue
        }
    }
    
    var videoURI: String? {
        get {
            if _videoURI == nil {
                _videoURI = self["videoURI"] as? String
            }
            return _videoURI
        }
        set {
            _videoURI = newValue
            self["videoURI"] = newValue
        }
    }
    
    var avatarURI: String? {
        get {
            if _avatarURI == nil {
                _avatarURI = self["avatarURI"] as? String
            }
            return _avatarURI
        }
        set {
            _avatarURI = newValue
            self["avatarURI"] = newValue
        }
    }
    
    var pageSize: Int {
        get {
            if _pageSize == -1 {
                _pageSize = (self["pageSize"] as? Int) ?? 30
            }
            return _pageSize
        }
        set {
            _pageSize = newValue
            self["pageSize"] = newValue
        }
    }
    
    func clear() {
        User.currentUser = nil
        authorization = nil
        authorizationCookie = nil
        EntryContext.sharedContext.clear()
    }
}