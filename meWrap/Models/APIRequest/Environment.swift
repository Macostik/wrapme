//
//  APIResponse.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/24/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import AFNetworking

class Environment: NSObject {
    
    static var ErrorDomain = "com.mewrap.error"
    
    static var ErrorResponseDataKey = "\(Environment.ErrorDomain).response.data"
    
    static var ErrorShowingBlock: (NSError -> Void)?
    
    static var Local = "local"
    static var QA = "qa"
    static var Production = "production"
    
    var endpoint: String
    
    var version: String
    
    var defaultImageURI: String
    
    var defaultVideoURI: String
    
    var defaultAvatarURI: String
    
    var s3Bucket: String
    
    var isProduction: Bool { return self == Environment.productionEnvironment }
    
    static let currentEnvironment = Environment.environments[ENV] ?? productionEnvironment
    
    static let productionEnvironment = Environment(
        endpoint: "https://prd-api.mewrap.me/api",
        version: "8",
        default_image_uri: "https://dhtwvi2qvu3d7.cloudfront.net/candies/image_attachments",
        default_avatar_uri: "https://dhtwvi2qvu3d7.cloudfront.net/users/avatars",
        default_video_uri: "https://dhtwvi2qvu3d7.cloudfront.net/candies/video_attachments",
        s3_bucket: "wraplive-production-upload-placeholder"
    )
    
    private static var environments = [
        Environment.Local : Environment(
            endpoint: "http://0.0.0.0:3000/api",
            version: "8",
            default_image_uri: "https://d2rojtzyvje8rl.cloudfront.net/candies/image_attachments",
            default_avatar_uri: "https://d2rojtzyvje8rl.cloudfront.net/users/avatars",
            default_video_uri: "https://d2rojtzyvje8rl.cloudfront.net/candies/video_attachments",
            s3_bucket: "wraplive-qa-upload-placeholder"
        ), Environment.QA : Environment(
            endpoint: "https://qa-api.mewrap.me/api",
            version: "8",
            default_image_uri: "https://d2rojtzyvje8rl.cloudfront.net/candies/image_attachments",
            default_avatar_uri: "https://d2rojtzyvje8rl.cloudfront.net/users/avatars",
            default_video_uri: "https://d2rojtzyvje8rl.cloudfront.net/candies/video_attachments",
            s3_bucket: "wraplive-qa-upload-placeholder"
        ), Environment.Production : productionEnvironment
    ]
    
    init(endpoint: String, version: String, default_image_uri: String, default_avatar_uri: String, default_video_uri: String, s3_bucket: String) {
        self.endpoint = endpoint
        self.version = version
        self.defaultImageURI = default_image_uri
        self.defaultAvatarURI = default_avatar_uri
        self.defaultVideoURI = default_video_uri
        self.s3Bucket = s3_bucket
    }
    
    override var description: String {
        return "environment \(name() ?? ""):\nendpoint=\(endpoint)\nversion=\(version)\ndefault_image_uri=\(defaultImageURI)\ndefault_avatar_uri=\(defaultVideoURI)\ndefault_video_uri=\(defaultAvatarURI)\ns3_bucket=\(s3Bucket)"
    }
    
    private func name() -> String? {
        let environments = Environment.environments
        for (name, _) in environments where environments[name] == self {
            return name
        }
        return nil
    }
    
    func testUsers() -> [Authorization] {
        var authorizations = [Authorization]()
        if let name = name(), let users = NSDictionary.plist("test-users")?[name] as? [[String:String]] {
            for user in users {
                let authorization = Authorization()
                authorization.deviceUID = user["deviceUID"] ?? ""
                authorization.countryCode = user["countryCode"]
                authorization.phone = user["phone"]
                authorization.email = user["email"]
                authorization.activationCode = user["activationCode"]
                authorization.password = user["password"]
                authorizations.append(authorization)
            }
        }
        return authorizations
    }
}

@objc enum ResponseCode: Int {
    case Default = 1
    case Success = 0
    case Failure = -1
    case DuplicatedUploading = 10
    case InvalidAttributes = 20
    case ContentUnavailable = 30
    case NotFoundEntry = 40
    case CredentialNotValid = 50
    case UploadFileNotFound = 100
    case EmailAlreadyConfirmed = 110
}

class Response: NSObject {
    var data = [String:AnyObject]()
    var code: ResponseCode = .Success
    var message = ""
    
    required init(dictionary: [String:AnyObject]) {
        super.init()
        if let message = dictionary["message"] as? String {
            self.message = message
        }
        if let data = dictionary["data"] as? [String:AnyObject] {
            self.data = data
        }
        if let returnCode = dictionary["return_code"] as? Int, let code = ResponseCode(rawValue: returnCode) {
            self.code = code
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
    
    static var showingBlock: (NSError -> Void)? {
        get {
            return Environment.ErrorShowingBlock
        }
        set {
            Environment.ErrorShowingBlock = newValue
        }
    }
    
    func show() {
        if code != NSURLErrorCancelled {
            NSError.showingBlock?(self)
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
    
    var responseData: NSDictionary? {
        return userInfo[Environment.ErrorResponseDataKey] as? NSDictionary
    }
}
