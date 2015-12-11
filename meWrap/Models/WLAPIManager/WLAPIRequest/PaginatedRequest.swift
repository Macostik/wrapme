//
//  PaginatedRequest.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/4/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

extension WLAPIRequest {
    func path(format: String, _ args: CVarArgType...) -> Self {
        path = String(format: format, arguments: args)
        return self
    }
}

@objc enum PaginatedRequestType: Int {
    case Fresh, Newer, Older
}

class PaginatedRequest: WLAPIRequest {

    var type: PaginatedRequestType = .Fresh
    
    var newer: NSDate?
    
    var older: NSDate?
    
    override init() {
        super.init()
        parametrize { (request, parameters) -> Void in
            if let request = request as? PaginatedRequest {
                switch request.type {
                case .Newer:
                    if let newer = request.newer {
                        parameters["offset_x_in_epoch"] = newer.timestamp
                    }
                    break
                case .Older:
                    if let newer = request.newer {
                        parameters["offset_x_in_epoch"] = newer.timestamp
                    }
                    if let older = request.older {
                        parameters["offset_y_in_epoch"] = older.timestamp
                    }
                    break
                default: break
                }
            }
        }
    }
    
    func fresh(success: ObjectBlock?, failure: FailureBlock?) {
        type = .Fresh
        super.send(success, failure: failure)
    }

    func newer(success: ObjectBlock?, failure: FailureBlock?) {
        type = .Newer
        super.send(success, failure: failure)
    }
    
    func older(success: ObjectBlock?, failure: FailureBlock?) {
        type = .Older
        super.send(success, failure: failure)
    }
}

extension PaginatedRequest {
    class func wraps(scope: String?) -> Self {
        return GET().path("wraps").parametrize({ (request, parameters) -> Void in
            if let scope = scope {
                parameters["scope"] = scope
            }
        }).parse({ (response, success, failure) -> Void in
            if let wraps = response.array("wraps") {
                success(Wrap.mappedEntries(Wrap.prefetchArray(wraps)))
            } else {
                success([])
            }
        })
    }
    
    class func candies(wrap: Wrap) -> PaginatedRequest {
        return GET().path("wraps/%@/candies", wrap.uid).forceParametrize({ (request, parameters) -> Void in
            if let request = request as? PaginatedRequest {
                switch request.type {
                case .Newer:
                    if let newer = request.newer {
                        parameters["offset_x_in_epoch"] = newer.timestamp
                    }
                    break
                case .Older:
                    if let older = wrap.candiesPaginationDate {
                        parameters["offset_y_in_epoch"] = older.timestamp
                    }
                    break
                default: break
                }
            }
        }).parse({ (response, success, failure) -> Void in
            if let candies = response.array("candies") where wrap.valid {
                let candies = Candy.mappedEntries(Candy.prefetchArray(candies), container: wrap)
                wrap.candiesPaginationDate = candies.last?.createdAt
                success(candies)
            } else {
                success([])
            }
        }).afterFailure({ (error) -> Void in
            if let error = error where wrap.valid && wrap.uploaded && error.isResponseError(.ContentUnavailable) {
                wrap.remove()
            }
        })
    }
    
    class func messages(wrap: Wrap) -> PaginatedRequest {
        return GET().path("wraps/%@/chats", wrap.uid).parse({ (response, success, failure) -> Void in
            if let chats = response.array("chats") where wrap.valid && !chats.isEmpty {
                success(Message.mappedEntries(Message.prefetchArray(chats), container: wrap))
                wrap.notifyOnUpdate(.ContentAdded)
            } else {
                success([])
            }
        }).afterFailure({ (error) -> Void in
            if let error = error where wrap.valid && wrap.uploaded && error.isResponseError(.ContentUnavailable) {
                wrap.remove()
            }
        })
    }
    
    class func wrap(wrap: Wrap, contentType: String?) -> PaginatedRequest {
        return GET().path("wraps/%@", wrap.uid).parametrize({ (request, parameters) -> Void in
            parameters["tz"] = NSTimeZone.localTimeZone().name
            if let contentType = contentType {
                parameters["pick"] = contentType
            }
            let request = request as! PaginatedRequest
            if let newer = request.newer where request.type == .Newer {
                parameters["condition"] = "newer_than"
                parameters["offset_in_epoch"] = newer.endOfDay().timestamp
            } else if let older = request.older where request.type == .Older {
                parameters["condition"] = "older_than"
                parameters["offset_in_epoch"] = older.startOfDay().timestamp
            }
        }).parse({ (response, success, failure) -> Void in
            if let dictionary = response.dictionary("wrap") where wrap.valid {
                success(wrap.update(Wrap.prefetchDictionary(dictionary)))
            } else {
                success(nil)
            }
        }).beforeFailure({ (error) -> Void in
            if let error = error where wrap.uploaded && error.isResponseError(.ContentUnavailable) {
                wrap.remove()
            }
        })
    }
}
