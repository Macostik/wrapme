//
//  LiveBroadcast.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/19/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

func ==(lv: LiveBroadcast?, rv: LiveBroadcast?) -> Bool {
    return lv?.wrap == rv?.wrap && lv?.broadcaster == rv?.broadcaster
}

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
            }
            broadcasts.append(broadcast)
            self.broadcasts[uid] = broadcasts
        }
    }
    
    class func removeBroadcast(broadcast: LiveBroadcast) {
        guard let wrap = broadcast.wrap, let uid = wrap.identifier else {
            return
        }
        guard var broadcasts = self.broadcasts[uid],
            let index = broadcasts.indexOf(broadcast) else {
            return
        }
        broadcasts.removeAtIndex(index)
        self.broadcasts[uid] = broadcasts
    }
    
    class func broadcastsForWrap(wrap: Wrap) -> [LiveBroadcast]? {
        guard let uid = wrap.identifier else {
            return nil
        }
        return self.broadcasts[uid]
    }
}
