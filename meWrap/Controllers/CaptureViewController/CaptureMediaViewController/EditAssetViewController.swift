//
//  EditAssetViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/11/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class EditAssetViewController: UIViewController {
    
    let imageView = ImageView(backgroundColor: UIColor.clearColor())
    
    lazy var videoPlayer = VideoPlayer()
    
    var asset: MutableAsset?
    
    override func loadView() {
        super.loadView()
        imageView.contentMode = .ScaleAspectFit
        view.add(imageView) { $0.edges.equalTo(view) }
        if asset?.type == .Video {
            
            imageView.add(videoPlayer, { (make) in
                make.edges.equalTo(imageView)
            })
            videoPlayer.url = asset?.original?.fileURL
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        videoPlayer.playing = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        videoPlayer.playing = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.url = asset?.large
    }
}

class EditAssetCell: EntryStreamReusableView<MutableAsset> {
    
    private lazy var imageView: ImageView = self.add(specify(ImageView(backgroundColor: UIColor.clearColor()), { $0.borderColor = UIColor.whiteColor() }), {
        $0.leading.top.trailing.equalTo(self).inset(1)
        $0.bottom.equalTo(self).inset(18)
    })
    private lazy var statusLabel: Label = self.add(Label(icon: "", size: 12), {
        $0.top.equalTo(self.imageView.snp_bottom)
        $0.bottom.equalTo(self)
        $0.trailing.equalTo(self).inset(2)
    })
    private lazy var videoIndicator: Label = self.add(Label(icon: "+", size: 20), { $0.top.trailing.equalTo(self.imageView).inset(2) })
    
    override func setup(asset: MutableAsset) {
        imageView.url = asset.small
        updateStatus()
        imageView.borderWidth = asset.selected ? 2 : 0
        videoIndicator.hidden = asset.type != .Video
    }
    
    func updateStatus() {
        if let asset = entry {
            statusLabel.text = "\(asset.comment?.isEmpty == false ? ";" : "") \(asset.edited ? "R" : "")".trim
        }
    }
}
