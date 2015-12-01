//
//  TodayViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/1/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import NotificationCenter
import MMWormhole

class TodayRecentUpdateCell : UITableViewCell {
    
    @IBOutlet weak var pictureView: UIImageView!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var wrapNameLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    var update: ExtensionUpdate! {
        didSet {
            guard let comment = update.comment else { return }
            guard let candy = update.candy else { return }
            wrapNameLabel.text = candy.wrap?.name
            if update.type == "comment" {
                timeLabel.text = comment.createdAt?.timeAgoStringAtAMPM()
                descriptionLabel.text = String(format: "%@ commented \"%@\"", comment.contributor?.name ?? "", comment.text ?? "")
            } else {
                timeLabel.text = candy.createdAt?.timeAgoStringAtAMPM()
                descriptionLabel.text = String(format: "%@ posted a new photo", candy.contributor?.name ?? "")
            }
            
            if let url = candy.asset where !url.isEmpty {
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

enum TodayState: Int {
    case ShowMore, ShowLess, OpenApp
}

let MaxRow: Int = 6
let MinRow: Int = 3

class TodayViewController: UIViewController {
    
    let wormhole = MMWormhole(applicationGroupIdentifier: "group.com.ravenpod.wraplive", optionalDirectory: "wormhole")
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    
    var updates = [ExtensionUpdate]() {
        didSet {
            if updates.count <= MinRow {
                state = .OpenApp
            } else {
                state = .ShowMore
            }
            tableView.reloadData()
        }
    }
    
    var state: TodayState = .OpenApp {
        didSet {
            switch state {
            case .ShowMore:
                moreButton.setTitle("more_today_stories".ls, forState: .Normal)
                signUpButton.hidden = true
                moreButton.hidden = false
                break
            case .ShowLess:
                moreButton.setTitle("less_today_stories".ls, forState: .Normal)
                signUpButton.hidden = true
                moreButton.hidden = false
                break
            case .OpenApp:
                signUpButton.hidden = false
                moreButton.hidden = true
                break
            }
        }
    }
    
    deinit {
        tableView.removeObserver(self, forKeyPath: "contentSize", context: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.addObserver(self, forKeyPath: "contentSize", options: .New, context: nil)
        wormhole.listenForMessageWithIdentifier("recentUpdatesResponse") { [weak self] (response) -> Void in
            self?.handleRecentUpdatesResponse(response)
        }
        fetchRecentUpdates()
    }
    
    private func handleRecentUpdatesResponse(response: AnyObject?) {
        if let updates = response as? [[String:AnyObject]] {
            self.updates = updates.map({ (dictionary) -> ExtensionUpdate in
                return ExtensionUpdate.fromDictionary(dictionary)
            })
        } else {
            updates = []
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        fetchRecentUpdates()
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "contentSize" {
            preferredContentSize = CGSize(width: 0.0, height: max(50, tableView.contentSize.height))
        }
    }
    
    func fetchRecentUpdates() -> NCUpdateResult {
        handleRecentUpdatesResponse(wormhole.messageWithIdentifier("recentUpdatesResponse"))
        wormhole.passMessageObject(nil, identifier: "recentUpdatesRequest")
        return .NewData
    }
    
    @IBAction func moreStories(sender: UIButton) {
        state = state == .ShowLess ? .ShowMore : .ShowLess
        tableView.reloadData()
    }
    
    @IBAction func singUpClick(sender: UIButton) {
        let request = ExtensionRequest(action: "authorize", parameters: nil)
        if let url = request.serializedURL() {
            extensionContext?.openURL(url, completionHandler: nil)
        }
    }
}

extension TodayViewController: NCWidgetProviding {
    func widgetPerformUpdateWithCompletionHandler(completionHandler: (NCUpdateResult) -> Void) {
        completionHandler(fetchRecentUpdates())
    }
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }
}

extension TodayViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(0, min(updates.count, state == .ShowLess ? MaxRow : MinRow))
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let update = updates[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(update.type ?? "candy", forIndexPath: indexPath) as! TodayRecentUpdateCell
        cell.update = update
        return cell
    }
}

extension TodayViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let update = updates[indexPath.row]
        if update.type == "comment" {
            guard let comment = update.comment else {
                return
            }
            let request = ExtensionRequest(action: "presentComment", parameters: ["uid":comment.uid])
            if let url = request.serializedURL() {
                extensionContext?.openURL(url, completionHandler: nil)
            }
        } else {
            guard let candy = update.candy else {
                return
            }
            let request = ExtensionRequest(action: "presentCandy", parameters: ["uid":candy.uid])
            if let url = request.serializedURL() {
                extensionContext?.openURL(url, completionHandler: nil)
            }
        }
        
    }
}