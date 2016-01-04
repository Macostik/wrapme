//
//  Network.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/17/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import AFNetworking

@objc protocol NetworkNotifying {
    optional func networkDidChangeReachability(network: Network)
}

class Network: Notifier {

    static let sharedNetwork = Network()
    
    var reachable: Bool {
        return AFNetworkReachabilityManager.sharedManager().reachable
    }
    
    override init() {
        super.init()
        let manager = AFNetworkReachabilityManager.sharedManager()
        manager.startMonitoring()
        Dispatch.mainQueue.after(0.2) { () -> Void in
            manager.setReachabilityStatusChangeBlock { [unowned self] (status) -> Void in
                if self.reachable {
                    Uploader.wrapUploader.start()
                }
                self.notify({ $0.networkDidChangeReachability?(self) })
            }
        }
    }
}
