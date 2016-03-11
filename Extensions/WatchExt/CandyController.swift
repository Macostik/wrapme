//
//  CandyController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/29/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import WatchKit
import WatchConnectivity

class CommentRow: NSObject {
    
    @IBOutlet weak var text: WKInterfaceLabel!
    @IBOutlet weak var avatar: WKInterfaceGroup!
    @IBOutlet weak var contributorNameLabel: WKInterfaceLabel!
    @IBOutlet weak var dateLabel: WKInterfaceLabel!
    
    var comment: ExtensionComment? {
        didSet {
            guard let comment = comment else { return }
            avatar.setURL(comment.contributor?.avatar)
            contributorNameLabel.setText(comment.contributor?.name)
            text.setText(comment.text)
            dateLabel.setText(comment.createdAt?.timeAgoStringAtAMPM())
        }
    }
}

class CandyController: WKInterfaceController {
    
    @IBOutlet weak var image: WKInterfaceGroup!
    @IBOutlet weak var table: WKInterfaceTable!
    @IBOutlet weak var photoByLabel: WKInterfaceLabel!
    @IBOutlet weak var wrapNameLabel: WKInterfaceLabel!
    @IBOutlet weak var dateLabel: WKInterfaceLabel!
    @IBOutlet weak var commentButton: WKInterfaceButton!
    
    var candy: ExtensionCandy?
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        commentButton.setTitle("comment".ls)
        if let candy = context as? ExtensionCandy {
            self.candy = candy
        }
    }
    
    private func update() {
        guard let candy = candy else { return }
        WCSession.defaultSession().getCandy(candy, success: { [weak self] (candy) -> Void in
            self?.candy = candy
            self?.setup()
            })
    }
    
    private func setup() {
        guard let candy = candy else { return }
        photoByLabel.setText(String(format: (candy.isVideo ? "formatted_video_by" : "formatted_photo_by").ls, candy.contributor?.name ?? ""))
        wrapNameLabel.setText(candy.wrap?.name)
        dateLabel.setText(candy.createdAt?.timeAgoStringAtAMPM())
        image.setURL(candy.asset)
        let comments = candy.comments
        table.setNumberOfRows(comments.count, withRowType: "comment")
        for (index, comment) in comments.enumerate() {
            let row = table.rowControllerAtIndex(index) as? CommentRow
            row?.comment = comment
        }
        
    }
    
    override func contextForSegueWithIdentifier(segueIdentifier: String) -> AnyObject? {
        return candy
    }
    
    override func willActivate() {
        super.willActivate()
        setup()
        update()
    }
    
    @IBAction func writeComment() {
        guard let candy = candy else {
            return
        }
        presentTextSuggestionsFromPlistNamed("comment_presets") { (text) -> Void in
            WCSession.defaultSession().postComment(text, candy: candy.uid, success: { [weak self] (reply) -> Void in
                self?.update()
                }, failure: { [weak self] (error) -> Void in
                    self?.pushControllerWithName("alert", context: error)
            })
        }
    }
}