//
//  InboxViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/13/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit

class InboxItem {
    let event: Event
    var unread: Bool
    let contribution: Contribution
    let date: NSDate
    init(event: Event, contribution: Contribution, date: NSDate, unread: Bool) {
        self.event = event
        self.contribution = contribution
        self.date = date
        self.unread = unread
    }
}

class InboxCell: StreamReusableView {
    
    internal var containerView = UIView()
    internal var headerView = UIView()
    internal var avatarView = ImageView(backgroundColor: UIColor.clearColor())
    internal var userNameLabel = Label(preset: .Small, textColor: Color.grayLighter)
    internal var timeLabel = Label(preset: .Smaller, textColor: Color.grayLighter)
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
            $0.leading.equalTo(headerView).offset(12)
            $0.top.equalTo(headerView).offset(9)
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

    }

    override func setup(entry: AnyObject?) {
        if let update = entry as? InboxItem {
            let contribution = update.contribution
            timeLabel.text = update.date.timeAgoStringAtAMPM()
            imageView.url = contribution.asset?.medium
            if update.unread {
                userNameLabel.textColor = Color.grayDark
                timeLabel.textColor = Color.grayDark
                containerView.shadowColor = Color.orange
            } else {
                containerView.shadowColor = Color.grayLighter
                userNameLabel.textColor = Color.grayLighter
                timeLabel.textColor = Color.grayLighter
            }
        }
    }
}

class InboxCommentCell: InboxCell {
    
    private var textView = Label(preset: .Normal, weight: .Regular, textColor: Color.grayLighter)
    
    static let DefaultHeight: CGFloat = Constants.screenWidth / 3 + 70
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        super.layoutWithMetrics(metrics)
        textView.numberOfLines = 0
        containerView.addSubview(textView)
        imageView.snp_makeConstraints {
            $0.trailing.equalTo(containerView)
            $0.top.equalTo(headerView.snp_bottom)
            $0.bottom.equalTo(containerView)
            $0.width.height.equalTo(self.snp_width).dividedBy(3)
        }
        textView.snp_makeConstraints {
            $0.leading.equalTo(containerView).inset(12)
            $0.trailing.equalTo(imageView.snp_leading).inset(-5)
            $0.top.equalTo(headerView.snp_bottom).inset(8)
            $0.height.lessThanOrEqualTo(imageView.snp_height).offset(5)
        }
    }

    override func setup(entry: AnyObject?) {
        if let update = entry as? InboxItem, let comment = update.contribution as? Comment {
            super.setup(entry)
            avatarView.url = comment.contributor?.avatar?.small
            userNameLabel.text = "\(comment.contributor?.name ?? ""):"
            textView.text = comment.text
            videoIndicator.hidden = comment.candy?.mediaType != .Video
            textView.textColor = update.unread ? Color.grayDark : Color.grayLighter
        }
    }
}

class InboxCandyCell: InboxCell {
    
    static let DefaultHeight: CGFloat = Constants.screenWidth / 2.5 + 70
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        super.layoutWithMetrics(metrics)
        imageView.snp_makeConstraints {
            $0.leading.trailing.equalTo(containerView)
            $0.top.equalTo(headerView.snp_bottom)
            $0.bottom.equalTo(containerView)
            $0.height.equalTo(self.snp_width).dividedBy(2.5)
        }
    }
    
    override func setup(entry: AnyObject?) {
        if let update = entry as? InboxItem, let candy = update.contribution as? Candy {
            super.setup(entry)
            if update.event == .Update {
                avatarView.url = candy.editor?.avatar?.small
                userNameLabel.text = String(format: "formatted_edited_by".ls, candy.editor?.name ?? "")
            } else {
                avatarView.url = candy.contributor?.avatar?.small
                userNameLabel.text = "\(candy.contributor?.name ?? "") \((candy.isVideo ? "posted_new_video" : "posted_new_photo").ls)"
            }
            videoIndicator.hidden = candy.mediaType != .Video
        }
    }
}

class InboxViewController: WrapSegmentViewController {

    lazy var dataSource: StreamDataSource<[InboxItem]> = StreamDataSource(streamView: self.streamView)
    
    @IBOutlet weak var streamView: StreamView!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet var clearLayoutPrioritizer: LayoutPrioritizer!
    
    var updates: [InboxItem] = [] {
        willSet {
            dataSource.items = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource.placeholderMetrics = StreamMetrics(loader: PlaceholderView.inboxPlaceholderLoader())
        streamView.contentInset = streamView.scrollIndicatorInsets
        let candyMetrics = dataSource.addMetrics(StreamMetrics(loader: StreamLoader<InboxCandyCell>()))
        let commentMetrics = dataSource.addMetrics(StreamMetrics(loader: StreamLoader<InboxCommentCell>()))
        
        candyMetrics.size = InboxCandyCell.DefaultHeight
        commentMetrics.size = InboxCommentCell.DefaultHeight
        candyMetrics.modifyItem = {
            $0.insets.origin.y = $0.position.index == 0 ? 0 : Constants.pixelSize
            let event = $0.entry as? InboxItem
            $0.hidden = !(event?.contribution is Candy)
        }
        commentMetrics.modifyItem = {
            $0.insets.origin.y = $0.position.index == 0 ? 0 : Constants.pixelSize
            let event = $0.entry as? InboxItem
            $0.hidden = !(event?.contribution is Comment)
        }
        
        candyMetrics.selection = { item, entry in
            if let event = entry as? InboxItem {
                ChronologicalEntryPresenter.presentEntry(event.contribution, animated: false)
            }
        }
        commentMetrics.selection = candyMetrics.selection
    }
    
    private func fetchUpdates() {
        guard let wrap = wrap else { return }
        var containsUnread = false
        var updates = [InboxItem]()
        for candy in wrap.candies {
            if candy.unread || candy.updateUnread { containsUnread = true }
            updates.append(InboxItem(event: .Add, contribution: candy, date: candy.createdAt, unread: candy.unread))
            if candy.editor != nil {
                updates.append(InboxItem(event: .Update, contribution: candy, date: candy.editedAt, unread: candy.updateUnread))
            }
            for comment in candy.comments {
                if comment.unread { containsUnread = true }
                updates.append(InboxItem(event: .Add, contribution: comment, date: comment.createdAt, unread: comment.unread))
            }
        }
        self.updates = updates.sort({ $0.date > $1.date })
        clearLayoutPrioritizer.defaultState = containsUnread
        clearButton.hidden = !containsUnread
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        fetchUpdates()
        Comment.notifier().addReceiver(self)
        Candy.notifier().addReceiver(self)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        Comment.notifier().removeReceiver(self)
        Candy.notifier().removeReceiver(self)
    }
    
    @IBAction func clearAll(sender: AnyObject) {
        updates.all({
            $0.unread = false
            $0.contribution.markAsUnread(false)
        })
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
