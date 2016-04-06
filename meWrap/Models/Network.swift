//
//  Network.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/17/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import Alamofire

@objc protocol NetworkNotifying {
    optional func networkDidChangeReachability(network: Network)
}

class Network: Notifier {

    static let sharedNetwork = Network()
    
    private var reachabilityManager = Alamofire.NetworkReachabilityManager()
    
    var reachable: Bool {
        return reachabilityManager?.isReachable ?? false
    }
    
    override init() {
        super.init()
        reachabilityManager?.startListening()
        Dispatch.mainQueue.after(0.2) { () -> Void in
            self.reachabilityManager?.listener = { _ in
                if self.reachable {
                    Uploader.wrapUploader.start()
                }
                self.notify({ $0.networkDidChangeReachability?(self) })
            }
        }
    }
}
