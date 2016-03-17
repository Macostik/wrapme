//
//  InboxViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/13/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit

class RecentUpdate {
    
    var event: Event
    
    var unread: Bool
    
    var contribution: Contribution
    
    var date: NSDate

    init(event: Event, contribution: Contribution, unread: Bool = true) {
        self.event = event
        self.contribution = contribution
        date = event == .Update ? contribution.editedAt : contribution.createdAt
        self.unread = unread
    }
}

class InboxCell: StreamReusableView {
    
    internal var containerView = UIView()
    internal var headerView = UIView()
    internal var avatarView = ImageView(backgroundColor: UIColor.clearColor())
    internal var userNameLabel = Label(preset: .Small, weight: UIFontWeightLight, textColor: Color.grayLighter)
    internal var timeLabel = Label(preset: .Smaller, weight: UIFontWeightLight, textColor: Color.grayLighter)
    internal var wrapLabel = Label(preset: .Small, weight: UIFontWeightLight, textColor: Color.grayLighter)
    internal var imageView = ImageView(backgroundColor: UIColor.clearColor())
    internal var videoIndicator = Label(icon: "+", size: 24)
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        addSubview(containerView)
        avatarView.cornerRadius = 18
        avatarView.defaultBackgroundColor = Color.grayLighter
        avatarView.defaultIconColor = UIColor.whiteColor()
        avatarView.defaultIconText = "&"
        containerView.addSubview(headerView)
        containerView.backgroundColor = UIColor.whiteColor()
        containerView.shadowOpacity = 1
        containerView.shadowOffset = CGSize(width: 1, height: 1)
        headerView.addSubview(avatarView)
        headerView.addSubview(userNameLabel)
        headerView.addSubview(timeLabel)
        containerView.addSubview(imageView)
        containerView.addSubview(videoIndicator)
        containerView.addSubview(wrapLabel)
        containerView.snp_makeConstraints {
            $0.top.equalTo(self)
            $0.leading.trailing.equalTo(self).inset(8)
        }
        headerView.snp_makeConstraints {
            $0.bottom.equalTo(imageView.snp_top)
            $0.leading.top.trailing.equalTo(containerView)
            $0.height.equalTo(54)
        }
        avatarView.snp_makeConstraints {
            $0.leading.top.equalTo(headerView).offset(12)
            $0.size.equalTo(36)
        }
        userNameLabel.snp_makeConstraints {
            $0.leading.equalTo(avatarView.snp_trailing).offset(12)
            $0.bottom.equalTo(avatarView.snp_centerY)
            $0.trailing.equalTo(headerView).inset(12)
        }
        timeLabel.snp_makeConstraints {
            $0.leading.equalTo(avatarView.snp_trailing).offset(12)
            $0.top.equalTo(avatarView.snp_centerY)
            $0.trailing.equalTo(headerView).inset(12)
        }
        videoIndicator.snp_makeConstraints { $0.trailing.top.equalTo(imageView).inset(12) }
        wrapLabel.snp_makeConstraints {
            $0.trailing.bottom.equalTo(containerView).inset(12)
            $0.top.equalTo(imageView.snp_bottom).offset(12)
            $0.leading.greaterThanOrEqualTo(containerView).inset(12)
        }
    }

    override func setup(entry: AnyObject?) {
        if let update = entry as? RecentUpdate {
            let contribution = update.contribution
            timeLabel.text = update.date.timeAgoStringAtAMPM()
            imageView.url = contribution.asset?.medium
            if contribution.unread && update.unread {
                userNameLabel.textColor = Color.grayDark
                timeLabel.textColor = Color.grayDark
                wrapLabel.textColor = Color.grayDark
                containerView.shadowColor = Color.orange
            } else {
                containerView.shadowColor = Color.grayLighter
                userNameLabel.textColor = Color.grayLighter
                timeLabel.textColor = Color.grayLighter
                wrapLabel.textColor = Color.grayLighter
            }
        }
    }
}

class InboxCommentCell: InboxCell {
    
    private var textView = Label(preset: .Normal, weight: UIFontWeightRegular, textColor: Color.grayLighter)
    
    static let DefaultHeight: CGFloat = Constants.screenWidth / 3 + 106.0
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        super.layoutWithMetrics(metrics)
        textView.numberOfLines = 0
        containerView.addSubview(textView)
        imageView.snp_makeConstraints {
            $0.trailing.equalTo(containerView)
            $0.top.equalTo(headerView.snp_bottom)
            $0.width.height.equalTo(self.snp_width).dividedBy(3)
        }
        textView.snp_makeConstraints {
            $0.leading.equalTo(containerView).inset(12)
            $0.trailing.equalTo(imageView.snp_leading).inset(-5)
            $0.top.equalTo(headerView.snp_bottom).inset(-5)
            $0.height.lessThanOrEqualTo(imageView.snp_height).inset(5)
        }
    }

    override func setup(entry: AnyObject?) {
        if let comment = (entry as? RecentUpdate)?.contribution as? Comment {
            super.setup(entry)
            avatarView.url = comment.contributor?.avatar?.small
            userNameLabel.text = "\(comment.contributor?.name ?? ""):"
            wrapLabel.text = comment.candy?.wrap?.name
            textView.text = comment.text
            videoIndicator.hidden = comment.candy?.mediaType != .Video
            textView.textColor = comment.unread ? Color.grayDark : Color.grayLighter
        }
    }
}

class InboxCandyCell: InboxCell {
    
    static let DefaultHeight: CGFloat = Constants.screenWidth / 2.5 + 106.0
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        super.layoutWithMetrics(metrics)
        imageView.snp_makeConstraints {
            $0.leading.trailing.equalTo(containerView)
            $0.top.equalTo(headerView.snp_bottom)
            $0.height.equalTo(self.snp_width).dividedBy(2.5)
        }
    }
    
    override func setup(entry: AnyObject?) {
        if let update = entry as? RecentUpdate, let candy = update.contribution as? Candy {
            super.setup(entry)
            if update.event == .Update {
                avatarView.url = candy.editor?.avatar?.small
                userNameLabel.text = String(format: "formatted_edited_by".ls, candy.editor?.name ?? "")
            } else {
                avatarView.url = candy.contributor?.avatar?.small
                userNameLabel.text = "\(candy.contributor?.name ?? "") \((candy.isVideo ? "posted_new_video" : "posted_new_photo").ls)"
            }
            wrapLabel.text = candy.wrap?.name
            videoIndicator.hidden = candy.mediaType != .Video
        }
    }
}

class InboxViewController: WrapSegmentViewController {

    lazy var dataSource: StreamDataSource = StreamDataSource(streamView: self.streamView)
    
    @IBOutlet weak var streamView: StreamView!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet var clearLayoutPrioritizer: LayoutPrioritizer!
    
    var updates: [RecentUpdate] = [] {
        willSet {
            dataSource.items = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource.placeholderMetrics = StreamMetrics(loader: PlaceholderView.inboxPlaceholderLoader())
        streamView.contentInset = streamView.scrollIndicatorInsets;
        let candyMetrics = dataSource.addMetrics(StreamMetrics(loader: LayoutStreamLoader<InboxCandyCell>()))
        let commentMetrics = dataSource.addMetrics(StreamMetrics(loader: LayoutStreamLoader<InboxCommentCell>()))
        
        candyMetrics.size = InboxCandyCell.DefaultHeight
        commentMetrics.size = InboxCommentCell.DefaultHeight
        candyMetrics.modifyItem = {
            $0.insets.origin.y = $0.position.index == 0 ? 0 : Constants.pixelSize
            let event = $0.entry as? RecentUpdate
            $0.hidden = !(event?.contribution is Candy)
        }
        commentMetrics.modifyItem = {
            $0.insets.origin.y = $0.position.index == 0 ? 0 : Constants.pixelSize
            let event = $0.entry as? RecentUpdate
            $0.hidden = !(event?.contribution is Comment)
        }
        
        candyMetrics.selection = { item, entry in
            if let event = entry as? RecentUpdate {
                ChronologicalEntryPresenter.presentEntry(event.contribution, animated: false)
            }
        }
        commentMetrics.selection = candyMetrics.selection
        
        Comment.notifier().addReceiver(self)
        Candy.notifier().addReceiver(self)
        streamView.layoutIfNeeded()
    }
    
    private func fetchUpdates() {
        guard let wrap = wrap else { return }
        var containsUnread = false
        var updates = [RecentUpdate]()
        for candy in wrap.candies {
            if candy.unread { containsUnread = true }
            updates.append(RecentUpdate(event: .Add, contribution: candy))
            if candy.editor != nil {
                updates.last?.unread = false
                updates.append(RecentUpdate(event: .Update, contribution: candy))
            }
            for comment in candy.comments {
                if comment.unread { containsUnread = true }
                updates.append(RecentUpdate(event: .Add, contribution: comment))
            }
        }
        self.updates = updates.sort({ $0.date > $1.date })
        clearLayoutPrioritizer.defaultState = containsUnread
        clearButton.hidden = !containsUnread
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        fetchUpdates()
    }
    
    @IBAction func clearAll(sender: AnyObject) {
        for update in updates {
            update.contribution.markAsUnread(false)
        }
        clearLayoutPrioritizer.defaultState = false
        clearButton.hidden = true
        dataSource.reload()
    }
}

extension InboxViewController: EntryNotifying {
    
    func notifier(notifier: EntryNotifier, didAddEntry entry: Entry) {
        guard let contributor = (entry as? Contribution)?.contributor where !contributor.current else { return }
        fetchUpdates()
    }
    
    func notifier(notifier: EntryNotifier, willDeleteEntry entry: Entry) {
        guard let contributor = (entry as? Contribution)?.contributor where !contributor.current else { return }
        Dispatch.mainQueue.async { [weak self] _ in
            self?.fetchUpdates()
        }
    }
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        fetchUpdates()
    }
}
