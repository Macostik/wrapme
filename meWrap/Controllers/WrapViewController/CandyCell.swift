//
//  CandyCell.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/19/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import SnapKit

private let CandyCellCommentAvatarSize: CGFloat = 24

class CandyCell: EntryStreamReusableView<Candy>, FlowerMenuConstructor, VideoPlayerOwner {
    
    let imageView = ImageView(backgroundColor: UIColor.whiteColor(), placeholder: ImageView.Placeholder.white.photoStyle(56))
    let commentLabel = Label(preset: .Smaller, textColor: UIColor.whiteColor())
    let gradientView = GradientView(startColor: UIColor.blackColor().colorWithAlphaComponent(0.8))
    private let mediaCommentIndicator = UserAvatarView(cornerRadius: CandyCellCommentAvatarSize/2, backgroundColor: Color.orange, placeholderSize: CandyCellCommentAvatarSize/2)
    private let spinner = specify(UIActivityIndicatorView(activityIndicatorStyle: .White)) {
        $0.color = Color.grayLightest
        $0.hidesWhenStopped = true
    }
    
    private var textCommentConstraint: Constraint!
    
    private var playVideoButton = Button(icon: ",", size: 24, textColor: .whiteColor())
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        
        if !metrics.disableMenu {
            FlowerMenu.sharedMenu.registerView(self)
        }
        
        let pressedStateButton = Button(type: .Custom)
        pressedStateButton.addTarget(self, action: #selector(self.selectAction), forControlEvents: .TouchUpInside)
        pressedStateButton.highlightedColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
        pressedStateButton.normalColor = UIColor.clearColor()
        pressedStateButton.exclusiveTouch = true
        add(imageView) { $0.edges.equalTo(self) }
        add(pressedStateButton) { make in
            make.edges.equalTo(self)
        }
        add(gradientView) { make in
            make.leading.bottom.trailing.equalTo(self)
            make.height.equalTo(36)
        }
        mediaCommentIndicator.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        mediaCommentIndicator.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        commentLabel.textAlignment = .Center
        commentLabel.numberOfLines = 2
        gradientView.add(commentLabel) { make in
            make.trailing.equalTo(gradientView).offset(-4)
            make.centerY.equalTo(gradientView)
            textCommentConstraint = make.leading.equalTo(gradientView).offset(4).constraint
        }
		mediaCommentIndicator.setBorder(color: Color.orange)
        gradientView.add(mediaCommentIndicator) { make in
            make.centerY.equalTo(gradientView)
            make.leading.equalTo(gradientView).offset(3)
			make.size.equalTo(CandyCellCommentAvatarSize)
        }
        
        imageView.add(spinner) {
            $0.center.equalTo(imageView)
        }
        imageView.spinner = spinner
        playVideoButton.addTarget(self, touchUpInside: #selector(self.playVideo))
        playVideoButton.setTitleColor(Color.grayLight, forState: .Highlighted)
        add(playVideoButton) { (make) in
            make.trailing.equalTo(self).offset(-5)
            make.top.equalTo(self).offset(3)
        }
    }
    
    func constructFlowerMenu(menu: FlowerMenu) {
        guard let candy = entry else {
            return
        }
        
        if candy.updateError() == nil && !candy.isVideo {
            
            menu.addEditPhotoAction({
                DownloadingView.downloadCandyImage(candy, success: { (image) -> Void in
                    ImageEditor.editImage(image) { candy.editWithImage($0) }
                    }, failure: { $0?.show() })
            })
            
            menu.addDrawPhotoAction({
                DownloadingView.downloadCandyImage(candy, success: { (image) -> Void in
                    DrawingViewController.draw(image, wrap: candy.wrap) { candy.editWithImage($0) }
                    }, failure: { $0?.show() })
            })
        }
        
        menu.addDownloadAction({
            candy.download({ () -> Void in
                Toast.showDownloadingMediaMessageForCandy(candy)
                }, failure: { $0?.show() })
        })
        
        menu.addShareAction({
            DownloadingView.downloadCandy(candy, message: "downloading_media_for_sharing".ls, success: { [weak self] (url) in
                let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                activityVC.popoverPresentationController?.sourceView = self
                UINavigationController.main.presentViewController(activityVC, animated: true, completion: nil)
                })
        })
        
        if candy.deletable {
            menu.addDeleteAction({ [weak self] in
                UIAlertController.confirmCandyDeleting(candy, success: { (_) -> Void in
                    self?.userInteractionEnabled = false
                    candy.delete({ (_) -> Void in
                        self?.userInteractionEnabled = true
                        }, failure: { (error) -> Void in
                            error?.show()
                            self?.userInteractionEnabled = true
                    })
                    }, failure: nil)
            })
        } else {
            menu.addReportAction({
                let controller = ReportViewController(candy: candy)
                UINavigationController.main.presentViewController(controller, animated: false, completion: nil)
            })
        }
    }
    
    override func didDequeue() {
        super.didDequeue()
        imageView.image = nil
    }
    
    private var uploadingView: UploadingView? {
        didSet {
            if oldValue?.superview == self {
                oldValue?.removeFromSuperview()
            }
            if let uploadingView = uploadingView {
                uploadingView.frame = bounds
                addSubview(uploadingView)
                uploadingView.update()
            }
        }
    }
    
    override func setupEmpty() {
        userInteractionEnabled = true
        exclusiveTouch = true
        uploadingView = nil
        imageView.url = nil
        commentLabel.superview?.hidden = true
    }
    
    override func willEnqueue() {
        super.willEnqueue()
        videoPlayer?.removeFromSuperview()
    }
    
    private var videoPlayer: VideoPlayer?
    
    func playVideo() {
        CandyCell.videoCandy = entry
        VideoPlayer.owner = self
        let player = VideoPlayer.createPlayerView()
        player.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        player.url = entry?.asset?.smallVideoURL()
        player.frame = bounds
        insertSubview(player, belowSubview: gradientView)
        player.playing = true
        videoPlayer = player
        playVideoButton.hidden = true
        player.add(player.replayButton) { (make) in
            make.center.equalTo(playVideoButton)
        }
    }
    
    func videoPlayerDidChangeOwner() {
        playVideoButton.hidden = false
        videoPlayer?.removeFromSuperview()
    }
    
    weak static var videoCandy: Candy?
    
    override func setup(candy: Candy) {
        userInteractionEnabled = true
        exclusiveTouch = true
        imageView.url = candy.asset?.small
        uploadingView = candy.uploadingView
        
        playVideoButton.hidden = candy.mediaType != .Video
        if playVideoButton.hidden == false && (CandyCell.videoCandy == nil || CandyCell.videoCandy == candy) {
            CandyCell.videoCandy = candy
            playVideoButton.hidden = true
            Dispatch.mainQueue.async({ [weak self] () in
                self?.playVideo()
            })
        }
        
        if let comment = candy.latestComment  {
            let commentType = comment.commentType()
            if commentType == .Text {
                commentLabel.textAlignment = .Center
                textCommentConstraint.updateOffset(4)
                commentLabel.text = comment.text
                gradientView.hidden = comment.text?.isEmpty ?? true
                mediaCommentIndicator.hidden = true
                mediaCommentIndicator.image = nil
            } else  {
                commentLabel.textAlignment = .Left
                mediaCommentIndicator.hidden = false
                textCommentConstraint.updateOffset(CandyCellCommentAvatarSize + 6)
				mediaCommentIndicator.user = comment.contributor
                gradientView.hidden = false
                mediaCommentIndicator.startAnimating()
                commentLabel.text = comment.displayText(comment.isVideo ? "see_my_video_comment".ls : "see_my_photo_comment".ls)
            }
        } else {
            mediaCommentIndicator.image = nil
            commentLabel.text = nil
            gradientView.hidden = true
        }
    }
}