//
//  APIResponse.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/24/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import AFNetworking
import PubNub

struct Environment: CustomStringConvertible {
    
    static var ErrorDomain = "com.mewrap.error"
    static var ErrorResponseDataKey = "\(Environment.ErrorDomain).response.data"
    
    static var Local = "local"
    static var QA = "qa"
    static var Production = "production"
    
    static let names = [QA, Production]
    
    static let isProduction = ENV == Production
    
    let name: String
    let endpoint: String
    let version: String
    let pubnub: (publishKey: String, subscribeKey: String)
    let defaultImageURI: String
    let defaultVideoURI: String
    let defaultAvatarURI: String
    let s3Bucket: String
    let newRelicToken: String
    let GAITrackingId: String?
    
    static let current = Environment.environmentNamed(NSUserDefaults.standardUserDefaults().environment ?? ENV)
    
    static func environmentNamed(name: String) -> Environment {
        switch name {
        case Environment.Local: return Environment(
            name: name,
            endpoint: "http://0.0.0.0:3000/api",
            version: "8",
            pubnub: ("pub-c-16ba2a90-9331-4472-b00a-83f01ff32089", "sub-c-bc5bfa70-d166-11e3-8d06-02ee2ddab7fe"),
            defaultImageURI: "https://d2rojtzyvje8rl.cloudfront.net/candies/image_attachments",
            defaultVideoURI: "https://d2rojtzyvje8rl.cloudfront.net/candies/video_attachments",
            defaultAvatarURI: "https://d2rojtzyvje8rl.cloudfront.net/users/avatars",
            s3Bucket: "wraplive-qa-upload-placeholder",
            newRelicToken: "AA0d33ab51ad09e9b52f556149e4a7292c6d4c480c",
            GAITrackingId: nil
            )
        case Environment.QA: return Environment(
            name: name,
            endpoint: "https://qa-api.mewrap.me/api",
            version: "8",
            pubnub: ("pub-c-16ba2a90-9331-4472-b00a-83f01ff32089", "sub-c-bc5bfa70-d166-11e3-8d06-02ee2ddab7fe"),
            defaultImageURI: "https://d2rojtzyvje8rl.cloudfront.net/candies/image_attachments",
            defaultVideoURI: "https://d2rojtzyvje8rl.cloudfront.net/candies/video_attachments",
            defaultAvatarURI: "https://d2rojtzyvje8rl.cloudfront.net/users/avatars",
            s3Bucket: "wraplive-qa-upload-placeholder",
            newRelicToken: "AA0d33ab51ad09e9b52f556149e4a7292c6d4c480c",
            GAITrackingId: nil
            )
        default: return Environment(
            name: name,
            endpoint: "https://prd-api.mewrap.me/api",
            version: "8",
            pubnub: ("pub-c-87bbbc30-fc43-4f6b-b1f4-cedd5f30d5e8", "sub-c-6562fe64-4270-11e4-aed8-02ee2ddab7fe"),
            defaultImageURI: "https://dhtwvi2qvu3d7.cloudfront.net/candies/image_attachments",
            defaultVideoURI: "https://dhtwvi2qvu3d7.cloudfront.net/candies/video_attachments",
            defaultAvatarURI: "https://dhtwvi2qvu3d7.cloudfront.net/users/avatars",
            s3Bucket: "wraplive-production-upload-placeholder",
            newRelicToken: "AAd46869ec0b3558fb5890343d895b3acdd40ebaa8",
            GAITrackingId: "UA-60538241-1"
            )
        }
    }
    
    var description: String {
        return "environment \(name):\nendpoint=\(endpoint)\nversion=\(version)\ndefault_image_uri=\(defaultImageURI)\ndefault_avatar_uri=\(defaultVideoURI)\ndefault_video_uri=\(defaultAvatarURI)\ns3_bucket=\(s3Bucket)"
    }
    
    static func testUser(info: [String:String]) -> Authorization {
        let authorization = Authorization()
        authorization.deviceUID = info["deviceUID"] ?? ""
        authorization.countryCode = info["countryCode"]
        authorization.phone = info["phone"]
        authorization.email = info["email"]
        authorization.password = info["password"]
        return authorization
    }
    
    private static let separator = "9bv2t7"
    
    static func deserializeTestUser(string: String) -> Authorization? {
        let components = string.componentsSeparatedByString(separator)
        guard components.count == 5 else { return nil }
        let authorization = Authorization()
        authorization.deviceUID = components[0]
        authorization.countryCode = components[1].isEmpty ? nil : components[1]
        authorization.phone = components[2].isEmpty ? nil : components[2]
        authorization.email = components[3]
        authorization.password = components[4]
        return authorization
    }
    
    static func serializeTestUser(user: Authorization) -> String? {
        guard let email = user.email, let password = user.password else { return nil }
        return "\(user.deviceUID)\(separator)\(user.countryCode ?? "")\(separator)\(user.phone ?? "")\(separator)\(email ?? "")\(separator)\(password ?? "")"
    }
    
    static func addTestUser(authorization: Authorization, completion: (String? -> Void)? = nil) {
        completion?("This doesn't work yet")
    }
    
    static func removeTestUser(authorization: Authorization, completion: (Void -> Void)? = nil) {
        guard let channel = serializeTestUser(authorization) else {
            completion?()
            return
        }
        PubNub.sharedInstance.channelsForGroup("test-users") { (result, status) -> Void in
            if let channels = result?.data.channels where channels.contains(channel) {
                PubNub.sharedInstance.removeChannels([channel], fromGroup: "test-users", withCompletion: { _ in
                    completion?()
                })
            } else {
                completion?()
            }
        }
    }
    
    func testUsers(completion: [Authorization] -> Void) {
        var users = [Authorization]()
        (NSDictionary.plist("test-users")?[name] as? [[String:String]])?.all({
            users.append(Environment.testUser($0))
        })
        PubNub.sharedInstance.channelsForGroup("test-users") { (result, status) -> Void in
            result?.data.channels.all({ (channel) -> Void in
                if let user = Environment.deserializeTestUser(channel) {
                    users.insert(user, atIndex: 0)
                }
            })
            completion(users)
        }
    }
}

enum ResponseCode: Int {
    case Default = 1
    case Success = 0
    case Failure = -1
    case DuplicatedUploading = 10
    case InvalidAttributes = 20
    case ContentUnavailable = 30
    case NotFoundEntry = 40
    case CredentialNotValid = 50
    case InvalidOrAlreadyTakenEmail = 60
    case OperationNotPermitted = 70
    case ApprovalCodeNotMatched = 80
    case ApprovalCodeExpired = 90
    case UploadFileNotFound = 100
    case EmailAlreadyConfirmed = 110
}

class Response {
    var data = [String:AnyObject]()
    var code: ResponseCode = .Success
    var message = ""
    
    init(dictionary: [String:AnyObject]) {
        if let message = dictionary["message"] as? String {
            self.message = message
        }
        if let data = dictionary["data"] as? [String:AnyObject] {
            self.data = data
        }
        if let returnCode = dictionary["return_code"] as? Int {
            self.code = ResponseCode(rawValue: returnCode) ?? .Failure
        }
    }
    
    subscript(key: String) -> AnyObject? {
        return data[key]
    }
    
    func array(key: String) -> [[String:AnyObject]]? {
        return data[key] as? [[String:AnyObject]]
    }
    
    func dictionary(key: String) -> [String:AnyObject]? {
        return data[key] as? [String:AnyObject]
    }
}

extension NSError {
    
    convenience init(response: Response) {
        let userInfo: [String:AnyObject] = [
            NSLocalizedDescriptionKey : response.message,
            Environment.ErrorResponseDataKey : response.data
        ]
        self.init(code: response.code.rawValue, userInfo: userInfo)
    }
    
    convenience init(code: Int, userInfo: [String:AnyObject]) {
        self.init(domain: Environment.ErrorDomain, code: code, userInfo: userInfo)
    }
    
    convenience init(code: Int) {
        self.init(domain: Environment.ErrorDomain, code: code, userInfo: nil)
    }
    
    convenience init(code: Int, message: String) {
        self.init(code: code, userInfo: [NSLocalizedDescriptionKey:message])
    }
    
    convenience init(message: String) {
        self.init(code: ResponseCode.Default.rawValue, userInfo: [NSLocalizedDescriptionKey:message])
    }
    
    var isNetworkError: Bool {
        switch code {
        case NSURLErrorTimedOut,
        NSURLErrorCannotFindHost,
        NSURLErrorCannotConnectToHost,
        NSURLErrorNetworkConnectionLost,
        NSURLErrorDNSLookupFailed,
        NSURLErrorHTTPTooManyRedirects,
        NSURLErrorResourceUnavailable,
        NSURLErrorNotConnectedToInternet,
        NSURLErrorRedirectToNonExistentLocation,
        NSURLErrorInternationalRoamingOff,
        NSURLErrorSecureConnectionFailed,
        NSURLErrorCannotLoadFromNetwork:
            return true
        default:
            return false
        }
    }
    
    func show() {
        if code != NSURLErrorCancelled {
            Toast.show(errorMessage)
        }
    }
    
    func showNonNetworkError() {
        if !isNetworkError {
            show()
        }
    }
    
    var errorMessage: String {
        if domain == NSURLErrorDomain {
            switch code {
            case NSURLErrorTimedOut:
                return "connection_was_lost".ls
            case NSURLErrorCannotDecodeContentData:
                return "no_internet_connection".ls
            case NSURLErrorInternationalRoamingOff:
                return "roaming_is_off".ls
            default: break
            }
        } else if domain == AFURLResponseSerializationErrorDomain {
            switch code {
            case NSURLErrorCannotDecodeContentData:
                return "no_internet_connection".ls
            default: break
            }
        }
        return localizedDescription
    }
    
    func isResponseError(code: ResponseCode) -> Bool {
        return domain == Environment.ErrorDomain && self.code == code.rawValue
    }
    
    var responseData: [String:AnyObject]? {
        return userInfo[Environment.ErrorResponseDataKey] as? [String:AnyObject]
    }
}
