//
//  LiveBroadcast.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/19/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class LiveBroadcast: NSObject {

    weak var broadcaster: User?
    weak var wrap: Wrap?
    var title = ""
    var url = ""
    var channel = ""
    
    static var broadcasts = [String : [LiveBroadcast]]()
    
    class func addBroadcast(broadcast: LiveBroadcast) {
        if let wrap = broadcast.wrap, let uid = wrap.identifier {
            var broadcasts: [LiveBroadcast]! = self.broadcasts[uid]
            if broadcasts == nil {
                broadcasts = [LiveBroadcast]()
            } else {
                if let index = broadcasts.indexOf({ $0.channel == broadcast.channel }) {
                    broadcasts.removeAtIndex(index)
                }
            }
            broadcasts.append(broadcast)
            self.broadcasts[uid] = broadcasts
            broadcast.wrap?.notifyOnUpdate(.LiveBroadcastsChanged)
        }
    }
    
    class func removeBroadcast(broadcast: LiveBroadcast) {
        guard let wrap = broadcast.wrap, let uid = wrap.identifier else {
            return
        }
        guard var broadcasts = self.broadcasts[uid],
            let index = broadcasts.indexOf({ $0.channel == broadcast.channel }) else {
            return
        }
        broadcasts.removeAtIndex(index)
        self.broadcasts[uid] = broadcasts
        broadcast.wrap?.notifyOnUpdate(.LiveBroadcastsChanged)
    }
    
    class func refreshBroadcasts(newBroadcasts: [String : [LiveBroadcast]]) {
        self.broadcasts = newBroadcasts
        for (_, broadcasts) in newBroadcasts {
            broadcasts.first?.wrap?.notifyOnUpdate(.LiveBroadcastsChanged)
        }
    }
    
    class func broadcastsForWrap(wrap: Wrap) -> [LiveBroadcast]? {
        guard let uid = wrap.identifier else {
            return nil
        }
        return self.broadcasts[uid]
    }
}
