//
//  CommentCell.swift
//  meWrap
//
//  Created by Yura Granchenko on 08/02/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import MobileCoreServices

class CommentCell: StreamReusableView {
    
    static let CommentLabelLenght = 250
    static let AuthorLabelHeight = 20
    static let MinimumCellHeight = 50
    static let LineHeadIndent = 16
    static let CommentItemIdentifier = "CommentCell"
    
    @IBOutlet weak var authorImageView: ImageView!
    @IBOutlet weak var authorNameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var commentTextView: UILabel!
    @IBOutlet weak var indicator: EntryStatusIndicator!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        FlowerMenu.sharedMenu.registerView(self) { [weak self] (menu) -> Void in
            guard let comment = self?.entry as? Comment else { return }
            if comment.deletable {
                menu.addDeleteAction({ [weak self] _ in
                    self?.userInteractionEnabled = false
                    comment.delete ({ (_) -> Void in
                        self?.userInteractionEnabled = true
                        }, failure: { (error) in
                            error?.show()
                            self?.userInteractionEnabled = true
                    })
                    })
            }
            menu.addCopyAction({ UIPasteboard.generalPasteboard().string = comment.text })
        }
    }
    
    override func setup(entry: AnyObject?) {
        guard let comment = entry as? Comment else { return }
        userInteractionEnabled = true
        comment.markAsUnread(false)
        authorNameLabel.text = comment.contributor?.name
        authorImageView.url = comment.contributor?.avatar?.small
        dateLabel.text = comment.createdAt.timeAgoString()
        indicator.updateStatusIndicator(comment)
        commentTextView.text = comment.text
    }
}
