//
//  LiveBroadcastViewersViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/12/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit

class LiveBroadcastViewerCell: EntryStreamReusableView<User> {
    
    static let DefaultHeight: CGFloat = 56
    
    private var avatarView = ImageView(backgroundColor: UIColor.whiteColor())
    private var nameLabel = Label(preset: .Small, textColor: Color.grayDarker)
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        avatarView.cornerRadius = 24
        avatarView.defaultBackgroundColor = Color.grayLighter
        avatarView.defaultIconColor = UIColor.whiteColor()
        avatarView.defaultIconText = "&"
        addSubview(avatarView)
        addSubview(nameLabel)
        
        avatarView.snp_makeConstraints(closure: {
            $0.leading.equalTo(self).offset(12)
            $0.centerY.equalTo(self)
            $0.size.equalTo(48)
        })
        
        nameLabel.snp_makeConstraints(closure: {
            $0.leading.equalTo(avatarView.snp_trailing).offset(12)
            $0.trailing.greaterThanOrEqualTo(self).offset(12)
            $0.centerY.equalTo(self)
        })
    }
    
    override func setup(user: User) {
        avatarView.url = user.avatar?.small
        nameLabel.text = user.name
    }
}

class LiveBroadcastViewersViewController: UIViewController {
    
    private let streamView = StreamView()
    
    private let numberOfViewersLabel = Label(preset: .Normal, weight: .Regular, textColor: Color.grayDarker)
    
    private lazy var dataSource: StreamDataSource<[User]> = StreamDataSource(streamView: self.streamView)
    
    let broadcast: LiveBroadcast
    
    private var slideTransition: SlideTransition?
    
    let contentView = UIView()
    
    required init(broadcast: LiveBroadcast) {
        self.broadcast = broadcast
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        let hideButton = UIButton(type: .Custom)
        hideButton.addTarget(self, touchUpInside: #selector(self.close(_:)))
        view.add(hideButton) { (make) in
            make.edges.equalTo(view)
        }
        view.backgroundColor = UIColor(white: 0, alpha: 0.7)
        contentView.clipsToBounds = true
        contentView.cornerRadius = 10
        contentView.backgroundColor = UIColor.whiteColor()
        view.add(contentView) { (make) in
            make.leading.trailing.equalTo(view).inset(24)
            make.centerY.equalTo(view)
            make.height.equalTo(300)
        }
        let topView = UIView()
        contentView.add(topView) { (make) in
            make.leading.top.trailing.equalTo(contentView)
            make.height.equalTo(44)
        }
        contentView.add(streamView) { (make) in
            make.top.equalTo(topView.snp_bottom)
            make.leading.bottom.trailing.equalTo(contentView)
        }
        topView.add(numberOfViewersLabel) { (make) in
            make.leading.equalTo(topView).inset(12)
            make.centerY.equalTo(topView)
        }
        
        slideTransition = SlideTransition(view: contentView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        slideTransition?.didFinish = { [weak self] _ in
            self?.removeFromContainerAnimated(false)
        }
        
        let metrics = StreamMetrics<LiveBroadcastViewerCell>(size: LiveBroadcastViewerCell.DefaultHeight)
        dataSource.addMetrics(metrics)
        update()
    }
    
    func update() {
        let cellHeight = LiveBroadcastViewerCell.DefaultHeight
        let viewers = broadcast.viewers
        numberOfViewersLabel.text = "\(viewers.count) \("live_viewers".ls)"
        contentView.snp_updateConstraints(closure: { (make) in
            make.height.equalTo(48 + min(cellHeight * 5, cellHeight * CGFloat(viewers.count)))
        })
        view.layoutIfNeeded()
        dataSource.items = viewers.sort({ $0.name > $1.name })
    }
    
    @IBAction func close(sender: AnyObject) {
        removeFromContainerAnimated(false)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
