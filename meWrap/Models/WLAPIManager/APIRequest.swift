//
//  APIRequest.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/17/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import AFNetworking

enum APIRequestMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

private struct APIRequestContainer<T> {
    var block: T
}

class APIRequest: NSObject {

    static let manager: AFHTTPRequestOperationManager = {
        let environment = Environment.currentEnvironment
        let manager = AFHTTPRequestOperationManager(baseURL: environment.endpoint.URL)
        let acceptHeader = "application/vnd.ravenpod+json;version=\(environment.version)"
        manager.requestSerializer.setValue(acceptHeader, forHTTPHeaderField: "Accept")
        manager.requestSerializer.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        manager.requestSerializer.timeoutInterval = 45
        manager.securityPolicy.allowInvalidCertificates = true
        manager.securityPolicy.validatesDomainName = false
        return manager
    }()
    
    private var method: APIRequestMethod = .GET
    
    required init(_ method: APIRequestMethod) {
        self.method = method
    }
    
    class func GET() -> Self { return self.init(.GET) }
    class func POST() -> Self { return self.init(.POST) }
    class func PUT() -> Self { return self.init(.PUT) }
    class func DELETE() -> Self { return self.init(.DELETE) }
    
    var path = ""
    
    func path(format: String, _ args: CVarArgType...) -> Self {
        path = String(format: format, arguments: args)
        return self
    }
    
    static var unauthorizedErrorBlock: ((APIRequest, NSError?) -> Void)?
    
    private var parameters = [String:AnyObject]()
    
    func parametrize() {
        parameters.removeAll()
        for parametrizer in parametrizers {
            parametrizer.block(self)
        }
    }
    
    var parser: (Response -> AnyObject?)?
    
    func parse(parser: Response -> AnyObject?) -> Self {
        self.parser = parser
        return self
    }
    
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
    
    private var parametrizers = [APIRequestContainer<(APIRequest) -> Void>]()
    func parametrize(parametrizer: (APIRequest) -> Void) -> Self {
        parametrizers.append(APIRequestContainer<(APIRequest) -> Void>(block: parametrizer))
        return self
    }
    
    var fileBlock: (APIRequest -> String?)?
    func file(block: APIRequest -> String?) -> Self {
        self.fileBlock = block
        return self
    }
    
    func forceParametrize(parametrizer: (APIRequest) -> Void) -> Self {
        parametrizers.removeAll()
        return parametrize(parametrizer)
    }
    
    var beforeFailure: FailureBlock?
    func beforeFailure(beforeFailure: FailureBlock) -> Self {
        self.beforeFailure = beforeFailure
        return self
    }
    
    var afterFailure: FailureBlock?
    func afterFailure(afterFailure: FailureBlock) -> Self {
        self.afterFailure = afterFailure
        return self
    }
    
    var failureValidator: ((APIRequest, NSError?) -> Bool)?
    func validateFailure(validateFailure: (APIRequest, NSError?) -> Bool) -> Self {
        failureValidator = validateFailure
        return self
    }
    
    private func request() -> NSMutableURLRequest? {
        guard let url = NSURL(string: path, relativeToURL:APIRequest.manager.baseURL)?.absoluteString else { return nil }
        let serializer = APIRequest.manager.requestSerializer
        if let file = fileBlock?(self) {
            let constructing: AFMultipartFormData -> Void = { (formData) -> Void in
                guard let url = file.fileURL else { return }
                guard let fileName = url.lastPathComponent else { return }
                guard file.isExistingFilePath else { return }
                do {
                    try formData.appendPartWithFileURL(url, name: "qqfile", fileName: fileName, mimeType: "image/jpeg")
                } catch {
                }
            }
            return serializer.multipartFormRequestWithMethod(method.rawValue, URLString: url, parameters: parameters, constructingBodyWithBlock: constructing, error: nil)
        } else {
            return serializer.requestWithMethod(method.rawValue, URLString: url, parameters: parameters, error: nil)
        }
    }
    
    var successBlock: ObjectBlock?
    var failureBlock: FailureBlock?
    
    weak var operation: AFHTTPRequestOperation?
    
    func send(success: ObjectBlock?, failure: FailureBlock?) -> AFHTTPRequestOperation? {
        successBlock = success
        failureBlock = failure
        return send()
    }
    
    func prepare() {
        cancel()
        parametrize()
    }
    
    func send() -> AFHTTPRequestOperation? {
        prepare()
        return enqueue()
    }
    
    func enqueue() -> AFHTTPRequestOperation? {
        guard let request = request() else {
            handleFailure(nil)
            return nil
        }
        Logger.log("\(method.rawValue) - \(path): \(parameters)", color: .Yellow)
        
        let manager = APIRequest.manager
        operation = manager.HTTPRequestOperationWithRequest(request, success: { (operation, responseObject) -> Void in
            let response = Response(dictionary: responseObject as! [String : AnyObject])
            if response.code == .Success {
                #if DEBUG
                    Logger.log("RESPONSE - \(self.path): \(response.data)", color: .Green)
                #else
                    Logger.log("RESPONSE - \(self.path)")
                #endif
                if let parser = self.parser {
                    let parsedObject = parser(response)
                    if let object = parsedObject {
                        Logger.log("PARSED RESPONSE - \(self.path): \(object)")
                    }
                    self.handleSuccess(parsedObject)
                } else {
                    self.handleSuccess(response)
                }
            } else {
                Logger.log("API ERROR \(response.code.rawValue) - \(self.path)", color: .Red)
                self.handleFailure(NSError(response: response))
            }
            self.trackServerTime(operation.response)
            }, failure: { (_, error) -> Void in
                Logger.log("ERROR - \(self.path): \(error)", color: .Red)
                self.handleFailure(error)
        })
        
        if let operation = operation {
            manager.operationQueue.addOperation(operation)
        }
        
        return operation
    }
    
    func cancel() {
        operation?.cancel()
    }
    
    func handleSuccess(object: AnyObject?) {
        let success = successBlock
        failureBlock = nil
        successBlock = nil
        success?(object)
    }
    
    var skipReauthorizing = false
    
    func handleFailure(error: NSError?) {
    
        guard (failureValidator?(self, error) ?? true) else {
            return
        }
        
        beforeFailure?(error)
        let response = error?.userInfo[AFNetworkingOperationFailingURLResponseErrorKey] as? NSHTTPURLResponse
        if let response = response where response.statusCode == 401 && !skipReauthorizing {
            NSUserDefaults.standardUserDefaults().authorizationCookie = nil
            Authorization.currentAuthorization.signIn().send({ (_) -> Void in
                self.enqueue()
                }, failure: { (error) -> Void in
                    if let block = APIRequest.unauthorizedErrorBlock where !(error?.isNetworkError ?? true) {
                        block(self, error)
                    } else {
                        self.handleFailure(error)
                    }
            })
        } else {
            let failure = self.failureBlock
            failureBlock = nil
            successBlock = nil
            failure?(error)
        }
        
        afterFailure?(error)
    }
    
    private static var previousDateString: String?
    private static var trackServerTimeFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "EEE',' dd' 'MMM' 'yyyy HH':'mm':'ss zzz"
        formatter.locale = NSLocale(localeIdentifier: "en_US")
        return formatter
    }()
    
    private func trackServerTime(response: NSHTTPURLResponse?) {
        if let dateString = response?.allHeaderFields["Date"] as? String {
            if APIRequest.previousDateString != dateString {
                if let date = APIRequest.trackServerTimeFormatter.dateFromString(dateString) {
                    NSDate.trackServerTime(date)
                    APIRequest.previousDateString = dateString
                }
            }
        }
    }
}
