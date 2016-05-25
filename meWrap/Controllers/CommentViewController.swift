//
//  CommentViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 5/16/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import AVFoundation

enum CommentAction {
    case None, Delete
}

class CommentLongPressGesture: UILongPressGestureRecognizer {
    
    var comment: (() -> Comment?)?
    
    class func gesture(comment: () -> Comment?) -> CommentLongPressGesture {
        let gesture = CommentLongPressGesture()
        gesture.addTarget(gesture, action: #selector(gesture.longPress(_:)))
        gesture.comment = comment
        return gesture
    }
    
    @objc private func longPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .Began {
            let controller = CommentViewController()
            controller.comment = comment?()
            controller.modalPresentationStyle = .OverCurrentContext
            UINavigationController.main.presentViewController(controller, animated: false, completion: nil)
            CommentViewController.current = controller
        } else if sender.state == .Ended || sender.state == .Cancelled {
            if let comment = comment?() where CommentViewController.current?.actionWith(sender) == .Delete {
                Dispatch.mainQueue.after(0.2) { () in
                    UIAlertController.confirmCommentDeleting({  _ in
                        comment.delete ({ (_) -> Void in
                            }, failure: { (error) in
                                error?.show()
                            })
                        }, failure: nil)
                }
            }
            UINavigationController.main.dismissViewControllerAnimated(false, completion: nil)
        }
    }
}

final class CommentViewController: UIViewController {
    
    static weak var current: CommentViewController?
    
    static let willAppear = BlockNotifier<CommentViewController>()
    
    static let willDisappear = BlockNotifier<CommentViewController>()
    
    private let name = Label(preset: .Small, weight: .Bold, textColor: UIColor.whiteColor())
    private let date = Label(preset: .Smaller, weight: .Regular, textColor: Color.grayLighter)
    private let indicator = EntryStatusIndicator(color: Color.orange)
    private let avatar = UserAvatarView(cornerRadius: 24)
    private let imageView = ImageView(backgroundColor: UIColor.clearColor())
    let deleteButton = Button.expandableCandyAction("n")
    
    weak var comment: Comment?
    
    override func loadView() {
        super.loadView()
        
        view.userInteractionEnabled = false
        
        avatar.defaultIconSize = 24
        avatar.borderColor = UIColor.whiteColor()
        avatar.borderWidth = 1
        
        view.add(UIVisualEffectView(effect: UIBlurEffect(style: .Dark)), { $0.edges.equalTo(view) })
        
        let contentView = UIView()
        contentView.backgroundColor = UIColor.blackColor()
        contentView.clipsToBounds = true
        contentView.cornerRadius = 4
        
        contentView.addSubview(avatar)
        contentView.addSubview(name)
        contentView.addSubview(date)
        contentView.addSubview(indicator)
        contentView.addSubview(imageView)
        
        if UIApplication.sharedApplication().statusBarOrientation.isPortrait {
            
            view.add(contentView) { (make) in
                make.leading.trailing.equalTo(view).inset(8)
                make.centerY.equalTo(view)
            }
            
            deleteButton.backgroundColor = UIColor(white: 0, alpha: 0.8)
            view.add(deleteButton) { (make) in
                make.leading.equalTo(contentView)
                make.top.equalTo(contentView.snp_bottom).inset(-8)
                make.size.equalTo(44)
            }
        } else {
            
            view.add(contentView) { (make) in
                make.top.bottom.equalTo(view).inset(8)
                make.centerX.equalTo(view)
            }
            
            deleteButton.backgroundColor = UIColor(white: 0, alpha: 0.8)
            view.add(deleteButton) { (make) in
                make.trailing.equalTo(contentView.snp_leading).inset(-8)
                make.bottom.equalTo(contentView)
                make.size.equalTo(44)
            }
        }
        
        imageView.snp_makeConstraints { (make) -> Void in
            make.leading.trailing.bottom.equalTo(contentView)
            make.width.equalTo(imageView.snp_height)
        }
        avatar.snp_makeConstraints { (make) -> Void in
            make.leading.top.equalTo(contentView).offset(16)
            make.bottom.equalTo(imageView.snp_top).offset(-16)
            make.size.equalTo(48)
        }
        name.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(avatar.snp_trailing).offset(16)
            make.bottom.equalTo(avatar.snp_centerY).offset(-2)
            make.trailing.lessThanOrEqualTo(contentView).inset(16)
        }
        
        date.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(avatar.snp_trailing).offset(16)
            make.top.equalTo(avatar.snp_centerY).offset(2)
        }
        
        indicator.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(date.snp_trailing).offset(10)
            make.centerY.equalTo(date)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        CommentViewController.willAppear.notify(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        CommentViewController.willDisappear.notify(self)
    }
    
    func actionWith(sender: UILongPressGestureRecognizer) -> CommentAction {
        if deleteButton.bounds.contains(sender.locationInView(deleteButton)) {
            return .Delete
        } else {
            return .None
        }
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    static func createPlayerView(muted: Bool = true) -> VideoPlayer {
        let playerView = VideoPlayer()
        (playerView.layer as? AVPlayerLayer)?.videoGravity = AVLayerVideoGravityResizeAspectFill
        playerView.muted = muted
        return playerView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let comment = comment {
            name.text = comment.contributor?.name
            date.text = comment.createdAt.timeAgoString()
            indicator.updateStatusIndicator(comment)
            avatar.user = comment.contributor
            imageView.url = comment.asset?.medium
            if comment.commentType() == .Video {
                let playerView = CommentViewController.createPlayerView(false)
                imageView.add(playerView) { $0.edges.equalTo(imageView) }
                playerView.url = comment.asset?.videoURL()
                playerView.playing = true
            }
            deleteButton.hidden = !comment.deletable || !comment.uploaded
        }
    }
}