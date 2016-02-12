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
    
    var setup: ExtensionWrap! {
        willSet {
            guard let extensionWrap = newValue else { return }
            wrapNameLabel.text = extensionWrap.name
            timeLabel.text = extensionWrap.updatedAt
            if let url = extensionWrap.lastCandy where !url.isEmpty  {
                if let image = InMemoryImageCache.instance[url] {
                    pictureView.image = image
                } else {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                        guard let _url = NSURL(string: url) else { return }
                        guard let data = NSData(contentsOfURL: _url) else { return }
                        guard let image = UIImage(data: data) else { return }
                        dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                            InMemoryImageCache.instance[url] = image
                            self?.pictureView.image = image
                            })
                    })
                }
            }
            
        }
    }
}

class ShareViewController: UIViewController {
    
    var wormhole = MMWormhole(applicationGroupIdentifier: "group.com.ravenpod.wraplive", optionalDirectory: "wormhole")
    
    @IBOutlet weak var tableView: UITableView!
    var wraps: [NSDictionary]?
    
    deinit {
        tableView.removeObserver(self, forKeyPath: "contentSize", context: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        wraps = NSUserDefaults.sharedUserDefaults?["allWraps"] as? [NSDictionary]
        tableView.addObserver(self, forKeyPath: "contentSize", options: .New, context: nil)
        
        wormhole.listenForMessageWithIdentifier("allWrapsResponse", listener: {(messageObject) -> Void in
            print (">>self - \(messageObject)<<")
            })
        wormhole.messageWithIdentifier("allWrapsResponse")
        wormhole.passMessageObject(nil, identifier: "allWrapsRequest")
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "contentSize" {
            preferredContentSize = CGSize(width: 0.0, height: max(65, tableView.contentSize.height))
        }
    }
}

extension ShareViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wraps?.count ?? 0
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("wrapCell", forIndexPath: indexPath) as! ShareWrapCell
        if let wrap = wraps?[indexPath.row] as? [String : AnyObject] {
            cell.setup = ExtensionWrap.fromDictionary(wrap)
        }
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