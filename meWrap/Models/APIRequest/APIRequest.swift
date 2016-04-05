//
//  APIRequest.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/17/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import Alamofire

private struct APIRequestContainer<T> {
    var block: T
}

private var previousDateString: String?
private var trackServerTimeFormatter: NSDateFormatter = {
    let formatter = NSDateFormatter()
    formatter.dateFormat = "EEE',' dd' 'MMM' 'yyyy HH':'mm':'ss zzz"
    formatter.locale = NSLocale(localeIdentifier: "en_US")
    return formatter
}()

private func trackServerTime(response: NSHTTPURLResponse?) {
    if let dateString = response?.allHeaderFields["Date"] as? String {
        if previousDateString != dateString {
            if let date = trackServerTimeFormatter.dateFromString(dateString) {
                NSDate.trackServerTime(date)
                previousDateString = dateString
            }
        }
    }
}

private var manager = createManager()

struct API {
    static func cancelAll() {
        manager = createManager()
    }
}

private func createManager() -> Alamofire.Manager {
    let manager = Alamofire.Manager()
    manager.startRequestsImmediately = true
    manager.session.configuration.timeoutIntervalForRequest = 45
    //        manager.securityPolicy.allowInvalidCertificates = true
    //        manager.securityPolicy.validatesDomainName = false
    return manager
}

private let headers = [
    "Accept": "application/vnd.ravenpod+json;version=\(Environment.current.version)",
    "Accept-Encoding": "gzip"
]

class APIRequest<ResponseType> {
    
    private var method: Alamofire.Method = .GET
    
    init(_ method: Alamofire.Method, _ path: String = "", modifier: (APIRequest<ResponseType> -> Void)? = nil, parser: (Response -> ResponseType)? = nil) {
        self.method = method
        self.path = path
        if let modifier = modifier {
            modifiers.append(APIRequestContainer(block: modifier))
        }
        self.parser = parser
    }
    
    var path = ""
    
    private var parameters = [String:AnyObject]()
    
    private func parametrize() {
        parameters.removeAll()
        for modifier in modifiers {
            modifier.block(self)
        }
    }
    
    var parser: (Response -> ResponseType)?
    
    subscript(key: String) -> AnyObject? {
        set {
            if let value = newValue {
                parameters[key] = value
            }
        }
        get {
            return parameters[key]
        }
    }
    
    private var modifiers = [APIRequestContainer<(APIRequest<ResponseType>) -> Void>]()
    func modify(modifier: (APIRequest) -> Void) -> Self {
        modifiers.append(APIRequestContainer(block: modifier))
        return self
    }
    
    var file: String?
    
    func clear() -> Self {
        modifiers.removeAll()
        return self
    }
    
    var beforeFailure: FailureBlock?
    
    var afterFailure: FailureBlock?
    
    var failureValidator: ((APIRequest, NSError?) -> Bool)?
    
    private func createRequest(responseJSON: Alamofire.Response<AnyObject, NSError> -> Void, failure: FailureBlock) {
        let url = Environment.current.endpoint + "/" + path
        if let file = file where file.isExistingFilePath {
            let fileURL = NSURL(fileURLWithPath: file)
            let fileName = fileURL.lastPathComponent ?? (GUID() + ".jpg")
            Alamofire.upload(
                method,
                url,
                headers: headers,
                multipartFormData: {
                    for (key, value) in self.parameters {
                        if let data = value as? NSData ?? value.description?.dataUsingEncoding(NSUTF8StringEncoding) {
                            $0.appendBodyPart(data: data, name: key)
                        } else if let data = value.description?.dataUsingEncoding(NSUTF8StringEncoding) {
                            $0.appendBodyPart(data: data, name: key)
                        }
                    }
                    $0.appendBodyPart(fileURL: fileURL, name: "qqfile", fileName: fileName, mimeType: "image/jpeg")
                },
                encodingCompletion: { encodingResult in
                    switch encodingResult {
                    case .Success(let request, _, _):
                        request.responseJSON(completionHandler: responseJSON)
                        self.task = request
                    case .Failure(let encodingError):
                        failure(encodingError as NSError)
                    }
            })
        } else {
            task = Alamofire.request(method, url, parameters: parameters, headers: headers).responseJSON(completionHandler: responseJSON)
        }
    }
    
    var successBlock: (ResponseType -> Void)?
    var failureBlock: FailureBlock?
    
    var uploadProgress: (NSProgress -> Void)?
    var downloadProgress: (NSProgress -> Void)?
    
    weak var task: Alamofire.Request?
    
    func send(success: (ResponseType -> Void)?, failure: FailureBlock? = nil) -> Request? {
        successBlock = success
        failureBlock = failure
        return send()
    }
    
    func prepare() {
        cancel()
        parametrize()
    }
    
    func send() -> Alamofire.Request? {
        prepare()
        return enqueue()
    }
    
    func enqueue() -> Alamofire.Request? {
        Logger.log("API call \(self.method.rawValue) \(self.path): \(parameters)", color: .Yellow)
        
        createRequest({ (response) -> Void in
            switch response.result {
            case .Success(let value):
                let _response = Response(dictionary: value as! [String : AnyObject])
                if _response.code == .Success {
                    Logger.debugLog("RESPONSE - \(self.path): \(_response.data)", color: .Green)
                    let parsedObject = self.parser?(_response)
                    if let object = parsedObject {
                        Logger.log("API response \(self.method.rawValue) \(self.path) Object(s) parsed and saved from the response: \(object)")
                    }
                    self.handleSuccess(parsedObject)
                } else {
                    Logger.log("API internal error \(self.method.rawValue) \(self.path): \(_response.code.rawValue) - \(_response.message)", color: .Red)
                    self.handleFailure(NSError(response: _response), response: response.response)
                }
                trackServerTime(response.response)
            case .Failure(let error):
                Logger.log("API error \(self.method.rawValue) \(self.path): \(error)", color: .Red)
                self.handleFailure(error, response: response.response)
            }
        }) { (error) -> Void in
            Logger.log("Encoding error \(self.method.rawValue) \(self.path): \(error)", color: .Red)
            self.handleFailure(error, response: nil)
        }
        return self.task
    }
    
    func cancel() { task?.cancel() }
    
    func handleSuccess(object: ResponseType?) {
        let success = successBlock
        failureBlock = nil
        successBlock = nil
        if let object = object {
            success?(object)
        }
    }
    
    var skipReauthorizing = false
    
    private func handleFailure(error: NSError?, response: NSHTTPURLResponse?) {
        
        guard (failureValidator?(self, error) ?? true) else { return }
        
        beforeFailure?(error)
        if response?.statusCode == 401 && !skipReauthorizing {
            NSUserDefaults.standardUserDefaults().authorizationCookie = nil
            reauthorize(error)
        } else {
            let failure = self.failureBlock
            failureBlock = nil
            successBlock = nil
            failure?(error)
        }
        
        afterFailure?(error)
    }
    
    private func reauthorize(error: NSError?) {
        if Authorization.current.canAuthorize {
            Authorization.current.signIn().send({ (_) -> Void in
                self.enqueue()
                }, failure: { (error) -> Void in
                    if !(error?.isNetworkError ?? true) {
                        self.reauthorizeFailed(error)
                    } else {
                        self.handleFailure(error, response: nil)
                    }
            })
        } else {
            self.handleFailure(error, response: nil)
        }
    }
    
    private func reauthorizeFailed(error: NSError?) {
        Logger.log("UNAUTHORIZED_ERROR: \(error)")
        let storyboard = UIStoryboard.signUp
        let window = UIWindow.mainWindow
        if window.rootViewController?.storyboard != storyboard {
            let topView = (window.rootViewController?.presentedViewController ?? window.rootViewController)?.view
            topView?.userInteractionEnabled = true
            UIAlertController.confirmReauthorization({ action in
                self.handleFailure(error, response: nil)
                Logger.log("ERROR - redirection to welcome screen, sign in failed: \(error)")
                NotificationCenter.defaultCenter.clear()
                NSUserDefaults.standardUserDefaults().clear()
                storyboard.present(true)
                topView?.userInteractionEnabled = true
                }, tryAgain: { action in
                    topView?.userInteractionEnabled = false
                    let successBlock = self.successBlock
                    let failureBlock = self.failureBlock
                    self.send({ object in
                        successBlock?(object)
                        topView?.userInteractionEnabled = true
                        }, failure: { error in
                            topView?.userInteractionEnabled = true
                            failureBlock?(error)
                    })
            })
        } else {
            self.handleFailure(error, response: nil)
        }
    }
}
