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
    
    enum Style {
        case Image, Text
    }
    
    let event: Event
    let style: Style
    var unread: Bool
    let contribution: Contribution
    let date: NSDate
    init(event: Event, style: Style = .Image, contribution: Contribution, date: NSDate, unread: Bool) {
        self.event = event
        self.contribution = contribution
        self.date = date
        self.unread = unread
        self.style = style
    }
}

class InboxCell: EntryStreamReusableView<InboxItem> {
    
    internal let avatarView = UserAvatarView(cornerRadius: 20, backgroundColor: UIColor.clearColor())
    internal let userNameLabel = Label()
    internal let timeLabel = Label()
    internal let imageView = ImageView(backgroundColor: UIColor.clearColor())
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        timeLabel.font = Font.Smaller + .Light
        add(SeparatorView(color: UIColor(white: 0, alpha: 0.54), contentMode: .Bottom)) { (make) in
            make.leading.bottom.trailing.equalTo(self)
            make.height.equalTo(1)
        }
    }

    override func setup(update: InboxItem) {
        timeLabel.text = update.date.timeAgoStringAtAMPM()
        if update.unread {
            userNameLabel.font = Font.Small + .Bold
            userNameLabel.textColor = UIColor(white: 0, alpha: 0.87)
            timeLabel.textColor = UIColor(white: 0, alpha: 0.87)
        } else {
            userNameLabel.font = Font.Smaller + .Regular
            userNameLabel.textColor = UIColor(white: 0, alpha: 0.54)
            timeLabel.textColor = UIColor(white: 0, alpha: 0.54)
        }
    }
}

class InboxTextCell: InboxCell {
    
    private let textView = Label()
    
    static let DefaultHeight: CGFloat = 120
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        textView.numberOfLines = 0
        imageView.cornerRadius = 8
        add(imageView) {
            $0.top.equalTo(self).offset(16)
            $0.trailing.equalTo(self).offset(-16)
            $0.bottom.equalTo(self).offset(-16)
            $0.size.equalTo(88)
        }
        add(avatarView) {
            $0.leading.top.equalTo(self).offset(16)
            $0.size.equalTo(40)
        }
        add(userNameLabel) {
            $0.leading.equalTo(avatarView.snp_trailing).offset(8)
            $0.bottom.equalTo(avatarView.snp_centerY)
            $0.trailing.lessThanOrEqualTo(imageView.snp_leading).offset(-16)
        }
        add(timeLabel) {
            $0.leading.equalTo(avatarView.snp_trailing).offset(8)
            $0.top.equalTo(avatarView.snp_centerY)
            $0.trailing.lessThanOrEqualTo(imageView.snp_leading).offset(-16)
        }
        add(textView) {
            $0.leading.equalTo(self).offset(16)
            $0.trailing.lessThanOrEqualTo(imageView.snp_leading).offset(-8)
            $0.top.equalTo(avatarView.snp_bottom).offset(8)
            $0.bottom.lessThanOrEqualTo(self).offset(-16)
        }
        super.layoutWithMetrics(metrics)
    }

    override func setup(update: InboxItem) {
        if let comment = update.contribution as? Comment {
            super.setup(update)
            if update.unread {
                textView.font = Font.Small + .Bold
                textView.textColor = UIColor(white: 0, alpha: 0.87)
            } else {
                textView.font = Font.Smaller + .Light
                textView.textColor = UIColor(white: 0, alpha: 0.54)
            }
            imageView.url = comment.candy?.asset?.small            
            if comment.commentType() == .Text {
                textView.text = comment.text
            } else {
                textView.text = comment.displayText((comment.isVideo ? "see_my_video_comment".ls : "see_my_photo_comment".ls))
            }
            avatarView.user = comment.contributor
            userNameLabel.text = "\(comment.contributor?.name ?? ""):"
        }
    }
}

class InboxImageCell: InboxCell {
    
    internal let headerView = UIView()
    
    static let DefaultHeight: CGFloat = 176
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        add(imageView) {
            $0.edges.equalTo(self)
        }
        add(headerView) {
            $0.leading.top.trailing.equalTo(self)
        }
        headerView.backgroundColor = UIColor(white: 1, alpha: 0.9)
        headerView.add(avatarView) {
            $0.leading.equalTo(headerView).offset(16)
            $0.top.equalTo(headerView).offset(8)
            $0.bottom.equalTo(headerView).offset(-8)
            $0.size.equalTo(40)
        }
        headerView.add(userNameLabel) {
            $0.leading.equalTo(avatarView.snp_trailing).offset(8)
            $0.bottom.equalTo(avatarView.snp_centerY)
            $0.trailing.lessThanOrEqualTo(headerView).offset(-16)
        }
        headerView.add(timeLabel) {
            $0.leading.equalTo(avatarView.snp_trailing).offset(8)
            $0.top.equalTo(avatarView.snp_centerY)
            $0.trailing.lessThanOrEqualTo(headerView).offset(-16)
        }
        super.layoutWithMetrics(metrics)
    }
    
    override func setup(update: InboxItem) {
        super.setup(update)
        if let candy = update.contribution as? Candy {
            imageView.url = candy.asset?.medium
            if update.event == .Update {
                avatarView.user = candy.editor
                userNameLabel.text = String(format: "formatted_edited_by".ls, candy.editor?.name ?? "")
            } else {
                avatarView.user = candy.contributor
                userNameLabel.text = "\(candy.contributor?.name ?? "") \((candy.isVideo ? "posted_new_video" : "posted_new_photo").ls)"
            }
        }
    }
}

extension StreamMetrics where T:InboxCell {
    
    private func setupWithStyle(style: InboxItem.Style) {
        modifyItem = {
            $0.hidden = ($0.entry as! InboxItem).style != style
        }
        selection = { view in
            if let event = view.entry {
                ChronologicalEntryPresenter.presentEntry(event.contribution, animated: false)
            }
        }
    }
}

final class InboxViewController: WrapBaseViewController {

    lazy var dataSource: StreamDataSource<[InboxItem]> = StreamDataSource(streamView: self.streamView)
    
    private let streamView = StreamView()
    private let clearButton = AnimatedButton(preset: .Normal, weight: .Regular, textColor: Color.orange)
    
    var updates: [InboxItem] = [] {
        willSet {
            dataSource.items = newValue
        }
    }
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = UIColor.whiteColor()
        streamView.frame = preferredViewFrame
        clearButton.setTitle("mark_all_as_read".ls, forState: .Normal)
        clearButton.backgroundColor = UIColor(white: 1, alpha: 0.9)
        clearButton.normalColor = UIColor(white: 1, alpha: 0.9)
        clearButton.clipsToBounds = true
        clearButton.circleView.clipsToBounds = true
        clearButton.circleView.setBorder(color: Color.orange)
        clearButton.cornerRadius = 22
        clearButton.setTitleColor(Color.orangeDark, forState: .Highlighted)
        clearButton.addTarget(self, touchUpInside: #selector(self.clearAll(_:)))
        view.add(streamView) { (make) in
            make.top.equalTo(view).offset(100)
            make.leading.bottom.trailing.equalTo(view)
        }
        view.add(clearButton) { (make) in
            make.bottom.equalTo(view).offset(-20)
            make.centerX.equalTo(view)
            make.height.equalTo(44)
            make.width.equalTo(180)
        }
        streamView.alwaysBounceVertical = true
        streamView.contentInset.bottom = 88
        streamView.placeholderViewBlock = PlaceholderView.inboxPlaceholder()
        dataSource.addMetrics(StreamMetrics<InboxImageCell>(size: InboxImageCell.DefaultHeight)).setupWithStyle(.Image)
        dataSource.addMetrics(StreamMetrics<InboxTextCell>(size: InboxTextCell.DefaultHeight)).setupWithStyle(.Text)
        
        streamView.trackScrollDirection = true
        streamView.didScrollUp = { [weak self] _ in
            self?.didScrollUp()
        }
        streamView.didScrollDown = { [weak self] _ in
            self?.didScrollDown()
        }
        
        dataSource.didEndDecelerating = { [weak self] _ in
            self?.streamView.direction = .Down
        }
    }
    
    private func didScrollUp() {
        clearButton.snp_remakeConstraints { (make) in
            make.top.equalTo(view.snp_bottom).offset(20)
            make.centerX.equalTo(view)
            make.height.equalTo(44)
            make.width.equalTo(180)
        }
        animate {
            view.layoutIfNeeded()
        }
    }
    
    private func defaultButtonsLayout() {
        clearButton.snp_remakeConstraints { (make) in
            make.bottom.equalTo(view).offset(-20)
            make.centerX.equalTo(view)
            make.height.equalTo(44)
            make.width.equalTo(180)
        }
    }
    
    private func didScrollDown() {
        defaultButtonsLayout()
        animate {
            view.layoutIfNeeded()
        }
    }
    
    private func fetchUpdates() {
        var containsUnread = false
        var updates = [InboxItem]()
        for candy in wrap.candies {
            if candy.unread || candy.updateUnread { containsUnread = true }
            if candy.contributor?.current == false {
                updates.append(InboxItem(event: .Add, contribution: candy, date: candy.createdAt, unread: candy.unread))
            }
            if candy.editor != nil && candy.editor?.current == false {
                updates.append(InboxItem(event: .Update, contribution: candy, date: candy.editedAt, unread: candy.updateUnread))
            }
            for comment in candy.comments {
                if comment.unread { containsUnread = true }
                if comment.contributor?.current == false {
                    updates.append(InboxItem(event: .Add, style: .Text, contribution: comment, date: comment.createdAt, unread: comment.unread))
                }
            }
        }
        self.updates = updates.sort({ $0.date > $1.date })
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
