//
//  RecentUpdatesController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/29/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import WatchKit
import WatchConnectivity

class RecentUpdateRow: NSObject {
    var update: ExtensionUpdate?
}

class CommentUpdateRow: RecentUpdateRow {
    
    @IBOutlet weak var text: WKInterfaceLabel!
    @IBOutlet weak var mainGroup: WKInterfaceGroup!
    @IBOutlet weak var avatar: WKInterfaceGroup!
    @IBOutlet weak var photoByLabel: WKInterfaceLabel!
    @IBOutlet weak var wrapNameLabel: WKInterfaceLabel!
    @IBOutlet weak var dateLabel: WKInterfaceLabel!
    
    override var update: ExtensionUpdate? {
        didSet {
            guard let update = update else { return }
            guard let comment = update.comment else { return }
            guard let candy = update.candy else { return }
            avatar.setURL(comment.contributor?.avatar)
            mainGroup.setURL(candy.asset)
            photoByLabel.setText(String(format: (candy.isVideo ? "formatted_video_by" : "formatted_photo_by").ls, candy.contributor?.name ?? ""))
            wrapNameLabel.setText(candy.wrap?.name)
            text.setText("\"\(comment.text ?? "")\"")
            dateLabel.setText(comment.createdAt?.timeAgoStringAtAMPM())
        }
    }
}

class CandyUpdateRow: RecentUpdateRow {
    
    @IBOutlet weak var group: WKInterfaceGroup!
    @IBOutlet weak var dataGroup: WKInterfaceGroup!
    @IBOutlet weak var photoByLabel: WKInterfaceLabel!
    @IBOutlet weak var wrapNameLabel: WKInterfaceLabel!
    @IBOutlet weak var dateLabel: WKInterfaceLabel!
    
    override var update: ExtensionUpdate? {
        didSet {
            guard let update = update else { return }
            guard let candy = update.candy else { return }
            photoByLabel.setText(String(format: (candy.isVideo ? "formatted_video_by" : "formatted_photo_by").ls, candy.contributor?.name ?? ""))
            wrapNameLabel.setText(candy.wrap?.name)
            dateLabel.setText(candy.createdAt?.timeAgoStringAtAMPM())
            group.setURL(candy.asset)
        }
    }
}

class RecentUpdatesController: WKInterfaceController {
    
    @IBOutlet weak var table: WKInterfaceTable!
    @IBOutlet weak var placeholderGroup: WKInterfaceGroup!
    @IBOutlet weak var noUpdatesLabel: WKInterfaceLabel!
    
    var isEmpty = false {
        didSet {
            table.setHidden(isEmpty)
            placeholderGroup.setHidden(!isEmpty)
        }
    }
    
    var updates = [ExtensionUpdate]() {
        didSet {
            let rowTypes = updates.map { (update) -> String in
                return update.type ?? ""
            }
            isEmpty = rowTypes.isEmpty
            table.setRowTypes(rowTypes)
            for (index, update) in updates.enumerate() {
                let row = table.rowControllerAtIndex(index) as? RecentUpdateRow
                row?.update = update
            }
        }
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        noUpdatesLabel.setText("no_recent_updates".ls)
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        pushControllerWithName("candy", context: updates[rowIndex].candy)
    }
    
    override func willActivate() {
        super.willActivate()
        update()
    }
    
    func update() {
        WCSession.defaultSession().recentUpdates({ [weak self] (updates) -> Void in
            self?.updates = updates ?? []
            }) { (error) -> Void in
        }
    }
}