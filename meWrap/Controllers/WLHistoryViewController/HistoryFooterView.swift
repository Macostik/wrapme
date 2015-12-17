//
//  HistoryFooterView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/15/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

private var TogglingInterval: Float = 4

class HistoryFooterView: GradientView {
    
    @IBOutlet weak var candyIndicator: EntryStatusIndicator!
    @IBOutlet weak var commentIndicator: EntryStatusIndicator!
    @IBOutlet weak var heightPrioritizer: LayoutPrioritizer!
    
    @IBOutlet weak var avatarImageView: ImageView!
    @IBOutlet weak var postLabel: WLLabel!
    @IBOutlet weak var timeLabel: WLLabel!
    @IBOutlet weak var commentLabel: SmartLabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        enqueueToggle(false)
    }
    
    private var _showsEditor = false
    private var showsEditor: Bool {
        set {
            if _showsEditor != newValue {
                _showsEditor = newValue
                if let candy = candy {
                    if setupAction(candy) {
                        let transition = CATransition.transition(kCATransitionPush, subtype: kCATransitionFromTop, duration: 0.25)
                        postLabel.superview?.addAnimation(transition)
                    }
                }
            }
        }
        get {
            return _showsEditor
        }
    }
    
    private func enqueueToggle(showsEditor: Bool) {
        self.showsEditor = showsEditor
        Dispatch.mainQueue.after(TogglingInterval, block: { [weak self] () -> Void in
            self?.enqueueToggle(!showsEditor)
            })
    }
    
    var candy: Candy? {
        didSet {
            if candy != oldValue {
                setup()
            }
            comment = candy?.latestComment
        }
    }
    
    var comment: Comment? {
        didSet {
            if comment != oldValue {
                if let comment = comment, let text = comment.text {
                    avatarImageView.hidden = false
                    commentLabel.hidden = false
                    commentIndicator.hidden = false
                    avatarImageView.url = comment.contributor?.avatar?.small
                    commentLabel.text = (comment.contributor?.current ?? false) ? "   \(text)" : text
                    commentIndicator.updateStatusIndicator(comment)
                    heightPrioritizer.defaultState = true
                } else {
                    avatarImageView.hidden = true
                    commentLabel.hidden = true
                    commentIndicator.hidden = true
                    heightPrioritizer.defaultState = false
                }
            }
        }
    }
    
    private func setup() {
        if let candy = candy {
            candy.markAsUnread(false)
            candyIndicator.updateStatusIndicator(candy)
            setupAction(candy)
        }
    }
    
    private func setupAction(candy: Candy) -> Bool {
        if showsEditor {
            if let editor = candy.editor {
                postLabel.text = String(format:"formatted_edited_by".ls, editor.name ?? "")
                timeLabel.text = candy.editedAt.timeAgoStringAtAMPM()
                return true
            } else {
                _showsEditor = false
                postLabel.text = String(format:(candy.isVideo ? "formatted_video_by" : "formatted_photo_by").ls, candy.contributor?.name ?? "")
                timeLabel.text = candy.createdAt.timeAgoStringAtAMPM()
                return false
            }
        } else {
            postLabel.text = String(format:(candy.isVideo ? "formatted_video_by" : "formatted_photo_by").ls, candy.contributor?.name ?? "")
            timeLabel.text = candy.createdAt.timeAgoStringAtAMPM()
            return true
        }
    }
    
    @IBAction func toggle(sender: AnyObject) {
        if postLabel.superview?.layer.animationKeys()?.count == 0 {
            showsEditor = !showsEditor
        }
    }
}
