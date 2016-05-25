//
//  NSUserDefaults+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/29/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import CryptoSwift
import AVFoundation

private var _authorization: Authorization?
private var _confirmationDate: NSDate?
private var _historyDate: NSDate?
private var _historyDates: [String:NSNumber]?
private var _handledNotifications: [String]?
private var _pageSize: Int = -1
private var _remoteLogging: Bool?

private var cipher = try! AES(key: [0xae, 0x51, 0x89, 0x51, 0x27, 0xab, 0x9f, 0xb9, 0xf6, 0x75, 0xe2, 0x09, 0x74, 0x4b, 0xc0, 0x8f, 0x48, 0x44, 0x1f, 0xe5, 0x24, 0x3d, 0x28, 0x25, 0xca, 0x35, 0x90, 0x05, 0x0b, 0x62, 0xc0, 0xbb], iv: [UInt8](count: AES.blockSize, repeatedValue: 0))

extension NSUserDefaults {
    
    // MARK: - defined fields
    
    var authorization: Authorization? {
        get {
            if _authorization == nil {
                NSKeyedUnarchiver.setClass(Authorization.classForKeyedUnarchiver(), forClassName: "WLAuthorization")
                if let data = NSUserDefaults.sharedUserDefaults?["encrypted_authorization"] as? NSData {
                    _authorization = (try? data.decrypt(cipher))?.unarchive()
                } else if let data = self["WrapLiveAuthorization"] as? NSData {
                    _authorization = data.unarchive()
                }
            }
            return _authorization
        }
        set {
            _authorization = newValue
            guard let sharedUserDefaults = NSUserDefaults.sharedUserDefaults else {
                return
            }
            if let authorization = newValue, let data = authorization.archive() {
                sharedUserDefaults["encrypted_authorization"] = try? data.encrypt(cipher)
                self["WrapLiveAuthorization"] = data
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
            Authorization.active = newValue != nil
        }
    }
    
    var environment: String? {
        get { return self["environment"] as? String }
        set { self["environment"] = newValue }
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
        get { return self["wrapLiveVersion"] as? String }
        set { self["wrapLiveVersion"] = newValue }
    }
    
    var numberOfLaunches: Int {
        get { return (self["WLNumberOfLaucnhes"] as? Int) ?? 0 }
        set { self["WLNumberOfLaucnhes"] = newValue }
    }
    
    var captureMediaDevicePosition: AVCaptureDevicePosition {
        get {
            guard let position = self["captureMediaDevicePosition"] as? Int else { return .Back }
            return AVCaptureDevicePosition(rawValue: position) ?? .Back
        }
        set { self["captureMediaDevicePosition"] = newValue.rawValue }
    }
    
    var captureMediaFlashMode: AVCaptureFlashMode {
        get {
            guard let flashMode = self["captureMediaFlashMode"] as? Int else { return .Off }
            return AVCaptureFlashMode(rawValue: flashMode) ?? .Off
        }
        set { self["captureMediaFlashMode"] = newValue.rawValue }
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
    
    var historyDates: [String:NSNumber] {
        get {
            if let dates = _historyDates {
                return dates
            } else {
                let dates = self["historyDates"] as? [String:NSNumber] ?? [String:NSNumber]()
                _historyDates = dates
                return dates
            }
        }
        set {
            _historyDates = newValue
            self["historyDates"] = newValue
        }
    }
    
    var handledNotifications: [String] {
        get {
            if let notifications = _handledNotifications {
                return notifications
            } else {
                let notifications = self["handledNotifications"] as? [String] ?? [String]()
                _handledNotifications = notifications
                return notifications
            }
        }
        set {
            _handledNotifications = newValue
            self["handledNotifications"] = newValue
        }
    }
    
    func clearHandledNotifications() {
        _handledNotifications = nil
        self["handledNotifications"] = nil
    }
    
    var recentEmojis: [String]? {
        get { return self["recentEmojis"] as? [String] }
        set { self["recentEmojis"] = newValue }
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
    
    var remoteLogging: Bool? {
        get {
            if _remoteLogging == nil {
                _remoteLogging = self["remote_logging"] as? Bool
            }
            return _remoteLogging
        }
        set {
            Logger.remoteLogging = newValue ?? false
            _remoteLogging = newValue
            self["remote_logging"] = newValue
        }
    }
    
    func clear() {
        User.currentUser = nil
        authorization = nil
        authorizationCookie = nil
        if let cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies {
            for cookie in cookies where cookie.name  == "_session_id" {
                NSHTTPCookieStorage.sharedHTTPCookieStorage().deleteCookie(cookie)
                break
            }
        }
        EntryContext.sharedContext.clear()
    }
}