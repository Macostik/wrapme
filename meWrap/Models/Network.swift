//
//  Network.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/17/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import Alamofire

final class Network: BlockNotifier<Bool> {

    static let network = Network()
    
    private var reachabilityManager = Alamofire.NetworkReachabilityManager()
    
    var reachable: Bool = true {
        didSet {
            if reachable != oldValue {
                self.notify(reachable)
            }
        }
    }
    
    override init() {
        super.init()
        if let manager = reachabilityManager {
            manager.startListening()
            reachable = manager.isReachable
            self.reachabilityManager?.listener = { _ in
                self.reachable = manager.isReachable
            }
        } else {
            reachable = false
        }
    }
}
