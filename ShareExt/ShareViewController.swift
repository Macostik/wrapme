//
//  ShareViewController.swift
//  ShareExt
//
//  Created by Yura Granchenko on 02/02/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import Social

class ShareWrapCell : UITableViewCell {
    
    @IBOutlet weak var pictureView: UIImageView!
    
    @IBOutlet weak var wrapNameLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
}

class ShareViewController: UIViewController {
    
    var wormhole = MMWormhole(applicationGroupIdentifier: "group.com.ravenpod.wraplive", optionalDirectory: "wormhole")
    
    @IBOutlet weak var tableView: UITableView!
    
    deinit {
        tableView.removeObserver(self, forKeyPath: "contentSize", context: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.addObserver(self, forKeyPath: "contentSize", options: .New, context: nil)
        wormhole.messageWithIdentifier("recentUpdatesResponse")
        wormhole.passMessageObject(nil, identifier: "allWrapsRequest")
        
        wormhole.listenForMessageWithIdentifier("allWrapsResponse", listener: {(messageObject) -> Void in
            print (">>self - \(messageObject)<<")
            })
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "contentSize" {
            preferredContentSize = CGSize(width: 0.0, height: max(65, tableView.contentSize.height))
        }
    }
    
}


extension ShareViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("wrapCell", forIndexPath: indexPath) as! ShareWrapCell
        return cell
    }
}

extension ShareViewController: UITableViewDelegate {
    //    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    //        if update.type == "comment" {
    //            guard let comment = update.comment else {
    //                return
    //            }
    //            let request = ExtensionRequest(action: "presentComment", parameters: ["uid":comment.uid])
    //            if let url = request.serializedURL() {
    //                extensionContext?.openURL(url, completionHandler: nil)
    //            }
    //        } else {
    //            guard let candy = update.candy else {
    //                return
    //            }
    //            let request = ExtensionRequest(action: "presentCandy", parameters: ["uid":candy.uid])
    //            if let url = request.serializedURL() {
    //                extensionContext?.openURL(url, completionHandler: nil)
    //            }
    //        }
    //        
    //    }
}