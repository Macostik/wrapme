//
//  RecentUpdatesViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/13/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

let WhatsUpCommentHorizontalSpacing: CGFloat = 144.0
let PaddingCell: CGFloat = 24.0
let HeightCell: CGFloat = Constants.screenWidth / 2.5 + 96.0

class RecentUpdateCell: StreamReusableView {
    
    @IBOutlet var pictureView: ImageView!
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var inWrapLabel: UILabel!
    @IBOutlet var textView: UILabel!
    @IBOutlet var wrapImageView: ImageView!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet weak var videoIndicator: UILabel!

    override func setup(entry: AnyObject) {
        if let update = entry as? RecentUpdate {
            let contribution = update.contribution
            contribution.markAsUnread(false)
            timeLabel.text =  update.date.isToday() ? update.date.stringWithTimeStyle(.ShortStyle) : "yesterday".ls
            wrapImageView.url = contribution.asset?.medium
        }
    }
}

class RecentCommentCell: RecentUpdateCell {

    override func setup(entry: AnyObject) {
        if let comment = (entry as? RecentUpdate)?.contribution as? Comment {
            super.setup(entry)
            pictureView.url = comment.contributor?.avatar?.small
            userNameLabel.text = "\(comment.contributor?.name ?? ""):"
            inWrapLabel.text = comment.candy?.wrap?.name
            textView.text = comment.text
            videoIndicator.hidden = comment.candy?.mediaType != .Video
        }
    }
}

class RecentCandyCell: RecentUpdateCell {
    
    override func setup(entry: AnyObject) {
        if let update = entry as? RecentUpdate, let candy = update.contribution as? Candy {
            super.setup(entry)
            if update.event == .Update {
                pictureView.url = candy.editor?.avatar?.small
                userNameLabel.text = String(format: "formatted_edited_by".ls, candy.editor?.name ?? "")
            } else {
                pictureView.url = candy.contributor?.avatar?.small
                userNameLabel.text = "\(candy.contributor?.name ?? "") \((candy.isVideo ? "posted_new_video" : "posted_new_photo").ls)"
            }
            inWrapLabel.text = candy.wrap?.name
            videoIndicator.hidden = candy.mediaType != .Video
        }
    }
}

class RecentUpdatesViewController: WLBaseViewController {

    var dataSource: StreamDataSource!
    @IBOutlet weak var streamView: StreamView!
    
    var events: [RecentUpdate]? {
        didSet {
            dataSource.items = events
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = StreamDataSource(streamView: streamView)
        dataSource.autogeneratedPlaceholderMetrics.identifier = "recent"
        streamView.contentInset = streamView.scrollIndicatorInsets;
        let candyMetrics = dataSource.addMetrics(StreamMetrics(identifier: "RecentCandyCell"))
        let commentMetrics = dataSource.addMetrics(StreamMetrics(identifier: "RecentCommentCell"))
        
        candyMetrics.size = HeightCell
        candyMetrics.insetsAt = { item -> CGRect in
            return CGRect.zero.offsetBy(dx: 0, dy: item.position.index == 0 ? 0 : Constants.pixelSize)
        }
        
        commentMetrics.size = HeightCell
        commentMetrics.insetsAt = { item -> CGRect in
            return CGRect.zero.offsetBy(dx: 0, dy: item.position.index == 0 ? 0 : Constants.pixelSize)
        }
        
        candyMetrics.hiddenAt = { item -> Bool in
            let event = item.entry as? RecentUpdate
            return !(event?.contribution is Candy)
        }
        
        commentMetrics.hiddenAt = { item -> Bool in
            let event = item.entry as? RecentUpdate
            return !(event?.contribution is Comment)
        }
        
        let itemSelected = { (item: StreamItem?, entry: AnyObject?) -> Void in
            if let event = entry as? RecentUpdate {
                ChronologicalEntryPresenter.presentEntry(event.contribution, animated: true)
            }
        }
        
        candyMetrics.selection = itemSelected
        commentMetrics.selection =  itemSelected
        
        events = RecentUpdateList.sharedList.updates
        Wrap.notifier().addReceiver(self)
        RecentUpdateList.sharedList.addReceiver(self)
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        RecentUpdateList.sharedList.update({ () -> Void in
            }) {(error) -> Void in
        }
    }
}

extension RecentUpdatesViewController: EntryNotifying {
    func notifier(notifier: EntryNotifier, willDeleteEntry entry: Entry) {
        if let wrap = entry as? Wrap {
            Toast.showMessageForUnavailableWrap(wrap)
        }
    }
}

extension RecentUpdatesViewController: RecentUpdateListNotifying {
    func recentUpdateListUpdated(list: RecentUpdateList) {
        events = list.updates
    }
}
