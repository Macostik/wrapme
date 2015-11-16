//
//  WhatsUpViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/13/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

let WhatsUpCommentHorizontalSpacing: CGFloat = 144.0
let PaddingCell: CGFloat = 24.0

class WhatsUpCell: StreamReusableView {
    
    @IBOutlet var pictureView: WLImageView!
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var inWrapLabel: UILabel!
    @IBOutlet var textView: UILabel!
    @IBOutlet var wrapImageView: WLImageView!
    @IBOutlet var timeLabel: UILabel!

    override func setup(entry: AnyObject!) {
        if let event = entry as? WhatsUpEvent {
            let contribution = event.contribution
            contribution.markAsRead()
            timeLabel.text = event.date?.timeAgoStringAtAMPM()
            wrapImageView.url = contribution.picture?.small
        }
    }

}

class CommentWhatsUpCell: WhatsUpCell {

    override func setup(entry: AnyObject!) {
        if let event = entry as? WhatsUpEvent, let comment = event.contribution as? Comment {
            super.setup(entry)
            pictureView.url = comment.contributor?.picture?.small
            userNameLabel.text = "\(comment.contributor?.name ?? ""):"
            inWrapLabel.text = comment.candy?.wrap?.name
            textView.text = comment.text
        }
    }

}

class CandyWhatsUpCell: WhatsUpCell {

    override func setup(entry: AnyObject!) {
        if let event = entry as? WhatsUpEvent, let candy = event.contribution as? Candy {
            super.setup(entry)
            if event.event == .Update {
                pictureView.url = candy.editor?.picture?.small
                userNameLabel.text = String(format: "formatted_edited_by".ls, candy.editor?.name ?? "")
            } else {
                pictureView.url = candy.contributor?.picture?.small
                userNameLabel.text = String(format: (candy.isVideo ? "formatted_video_by" : "formatted_photo_by").ls, candy.contributor?.name ?? "")
            }
            inWrapLabel.text = candy.wrap?.name
        }
    }
}

class WhatsUpViewController: WLBaseViewController {

    var dataSource: StreamDataSource!
    @IBOutlet var streamView: StreamView!
    
    var events: NSMutableOrderedSet? {
        didSet {
            dataSource.items = events
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = StreamDataSource(streamView: streamView)
        let candyMetrics = dataSource.addMetrics(StreamMetrics(identifier: "CandyWhatsUpCell"))
        
        candyMetrics.sizeAt = sizeForCandyAt
        candyMetrics.hiddenAt = {[unowned self] (position, metrics) -> Bool in
            let event = self.events?[position.index]
            return !(event?.contribution is Candy)
        }
        let commentMetrics = dataSource.addMetrics(StreamMetrics(identifier: "CommentWhatsUpCell"))
        
        commentMetrics.sizeAt = sizeForCommentAt
        commentMetrics.hiddenAt = {[unowned self] (position, metrics) -> Bool in
            let event = self.events?[position.index]
            return !(event?.contribution is Comment)
        }
        
        candyMetrics.selection = itemSelected
        commentMetrics.selection = itemSelected
        
        Wrap.notifier().addReceiver(self)
        
        events = NSMutableOrderedSet(orderedSet: WLWhatsUpSet.sharedSet().entries)
        WLWhatsUpSet.sharedSet().broadcaster.addReceiver(self)
    }
    
    func sizeForCandyAt(position: StreamPosition, metrics: StreamMetrics) -> CGFloat {
        let fontNormal = UIFont.lightFontNormal()
        let fontSmall = UIFont.lightFontSmall()
        return 2*floor(fontNormal?.lineHeight ?? 0) + floor(fontSmall?.lineHeight ?? 0) + PaddingCell
    }
    
    func sizeForCommentAt(position: StreamPosition, metrics: StreamMetrics) -> CGFloat {
        let event = events?[position.index]
        let font = UIFont.fontNormal()
        let textHeight = ((event?.contribution as! Comment).text! as NSString).heightWithFont(font!, width: WLConstants.screenWidth - WhatsUpCommentHorizontalSpacing)
        return textHeight + sizeForCandyAt(position, metrics: metrics)
    }
    
    func itemSelected(item: StreamItem?, entry: AnyObject?) {
//        [WLChronologicalEntryPresenter presentEntry:event.contribution animated:YES];
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        WLWhatsUpSet.sharedSet().update({ () -> Void in
            }) { (error) -> Void in
        }
    }
}

extension WhatsUpViewController: EntryNotifying {
    func notifier(notifier: EntryNotifier, willDeleteEntry entry: Entry) {
//        [WLToast showMessageForUnavailableWrap:(Wrap *)entry];
    }
}

extension WhatsUpViewController: WLWhatsUpSetBroadcastReceiver {
    func whatsUpBroadcaster(broadcaster: WLBroadcaster!, updated set: WLWhatsUpSet!) {
        events = NSMutableOrderedSet(orderedSet: set.entries)
    }
}
