//
//  PaginatedRequest.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/4/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import Alamofire

enum PaginatedRequestType {
    case Fresh, Newer, Older
}

final class PaginatedRequest<ResponseType>: APIRequest<ResponseType> {
    
    override init(_ method: Alamofire.Method, _ path: String = "", modifier: (APIRequest<ResponseType> -> Void)? = nil, parser: (Response -> ResponseType?)? = nil) {
        super.init(method, path, modifier: modifier, parser: parser)
    }
    
    var type: PaginatedRequestType = .Fresh
    
    var newer: NSDate?
    
    var older: NSDate?
    
    func modifyForPagination() {
        switch type {
        case .Newer:
            self["offset_x_in_epoch"] = newer?.timestamp
        case .Older:
            self["offset_y_in_epoch"] = older?.timestamp
        default: break
        }
    }
    
    func fresh(success: (ResponseType -> Void)?, failure: FailureBlock?) {
        type = .Fresh
        super.send(success, failure: failure)
    }
    
    func newer(success: (ResponseType -> Void)?, failure: FailureBlock?) {
        type = .Newer
        super.send(success, failure: failure)
    }
    
    func older(success: (ResponseType -> Void)?, failure: FailureBlock?) {
        type = .Older
        super.send(success, failure: failure)
    }
}
