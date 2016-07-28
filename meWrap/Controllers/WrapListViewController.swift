//
//  WrapListViewController.swift
//  meWrap
//
//  Created by Yura Granchenko on 25/02/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class WrapListViewController: BaseViewController {
    
    let items: [[String:String]]
    
    required init(items: [[String:String]]) {
        self.items = items
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var runQueue = RunQueue(limit: 1)
    private var assets: [MutableAsset]?
    private var text: String?
    
    private lazy var url: NSURL = NSURL.shareExtension()
    
    private let streamView = StreamView()
    lazy var wrapListDataSource: PaginatedStreamDataSource<PaginatedList<Wrap>> = PaginatedStreamDataSource(streamView: self.streamView)
    private let searchField = TextField()
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = UIColor.whiteColor()
        let navigationBar = UIView()
        navigationBar.backgroundColor = Color.orange
        self.navigationBar = view.add(navigationBar) { (make) in
            make.leading.top.trailing.equalTo(view)
            make.height.equalTo(64)
        }
        let backButton = Button(preset: .Small, weight: .Regular, textColor: UIColor.whiteColor())
        backButton.setTitle("cancel".ls, forState: .Normal)
        backButton.setTitleColor(UIColor.whiteColor().darkerColor(), forState: .Highlighted)
        backButton.addTarget(self, action: #selector(self.cancel(_:)), forControlEvents: .TouchUpInside)
        navigationBar.add(backButton) { (make) in
            make.leading.equalTo(navigationBar).inset(12)
            make.centerY.equalTo(navigationBar).offset(10)
        }
        let title = Label(preset: .Large, weight: .Regular, textColor: UIColor.whiteColor())
        title.text = "Select Wrap To Share"
        navigationBar.add(title) { (make) in
            make.centerX.equalTo(navigationBar)
            make.centerY.equalTo(navigationBar).offset(10)
        }
        self.navigationBar = navigationBar
        
        let searchView = UIView()
        view.add(searchView) { (make) in
            make.leading.trailing.equalTo(view)
            make.top.equalTo(navigationBar.snp_bottom)
            make.height.equalTo(44)
        }
        
        let searchIcon = Label(icon: "I", size: 17, textColor: Color.orange)
        searchIcon.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        searchIcon.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        searchView.add(searchIcon) { (make) in
            make.trailing.equalTo(searchView).offset(-12)
            make.centerY.equalTo(searchView)
        }
        
        searchField.font = Font.Small + .Light
        searchField.makePresetable(.Small)
        searchField.disableSeparator = true
        searchField.placeholder = "search_wraps".ls
        searchField.addTarget(self, action: #selector(self.searchTextChanged(_:)), forControlEvents: .EditingChanged)
        searchView.add(searchField) { (make) in
            make.leading.equalTo(searchView).offset(12)
            make.top.bottom.equalTo(searchView)
            make.trailing.equalTo(searchIcon.snp_leading).offset(-12)
        }
        
        let separator = SeparatorView(color: Color.grayLightest, contentMode: .Bottom)
        searchView.add(separator) { (make) in
            make.leading.bottom.trailing.equalTo(searchView)
            make.height.equalTo(1)
        }
        
        view.add(streamView) { (make) in
            make.leading.bottom.trailing.equalTo(view)
            make.top.equalTo(searchView.snp_bottom)
        }
        
        Keyboard.keyboard.handle(self, block: { [unowned self] (keyboard, willShow) in
            keyboard.performAnimation { () in
                self.streamView.snp_updateConstraints(closure: { (make) in
                    make.bottom.equalTo(self.view).offset(willShow ? -keyboard.height : 0)
                })
                self.streamView.layoutIfNeeded()
            }
            })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        streamView.placeholderViewBlock = PlaceholderView.sharePlaceholder()
        
        let metrics = wrapListDataSource.addMetrics(StreamMetrics<WrapCell>(size: 70))
        metrics.modifyItem = { [weak self] item in
            let wrap = item.entry as! Wrap
            if let text = self?.searchField.text where !text.isEmpty {
                item.hidden = wrap.name?.rangeOfString(text, options: .CaseInsensitiveSearch, range: nil, locale: nil) == nil
            } else {
                item.hidden = false
            }
        }
        metrics.selection = { [weak self] view in
            self?.searchField.resignFirstResponder()
            self?.shareContent(view.entry!)
        }
        metrics.finalizeAppearing = { _, view in
            view.swipeAction?.shouldBeginPanning = { _ in
                return false
            }
        }
        wrapListDataSource.items = specify(PaginatedList<Wrap>()) {
            $0.request = API.wraps(nil)
            $0.sorter = { $0.updatedAt > $1.updatedAt }
            $0.entries = User.currentUser?.sortedWraps ?? []
            $0.newerThen = { $0.first?.updatedAt }
            $0.olderThen = { $0.last?.updatedAt }
        }
        extractContent()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        view.layoutIfNeeded()
        wrapListDataSource.reload()
    }
    
    func extractContent() {
        let items = self.items.sort({ $0["createdAt"] < $1["createdAt"] })
        if let text = items.filter({ $0["type"] == "text" }).first {
            let textFile = url.URLByAppendingPathComponent(text["fileName"] ?? "")
            guard let data = NSData(contentsOfURL: textFile) else { return }
            self.text = String(data: data, encoding: NSUTF8StringEncoding)
        } else {
            if items.count <= 10 {
                assets = handleAssets(items)
            } else {
                Toast.show("upload_photos_limit_error".ls)
                assets = handleAssets(Array(items.prefix(10)))
            }
        }
    }
    
    func handleAssets(items: [[String:String]]) -> [MutableAsset] {
        return items.reduce([], combine: { (assets, file) -> [MutableAsset] in
            guard let type = file["type"] else { return assets }
            guard let fileName = file["fileName"] else { return assets }
            guard let path = url.URLByAppendingPathComponent(fileName).path else { return assets }
            let asset = MutableAsset()
            asset.date = NSDate.now()
            if type == "photo" {
                guard let image = UIImage(contentsOfFile: path) else { return assets }
                asset.type = .Photo
                runQueue.run({ finish in
                    asset.setImage(image, completion:finish)
                })
                return assets + [asset]
            } else if type == "video" {
                asset.type = .Video
                runQueue.run({ finish in
                    asset.setVideoFromRecordAtPath(path, completion: finish)
                })
                return assets + [asset]
            } else {
                return assets
            }
        })
    }
    
    @IBAction func cancel(sender: AnyObject?) {
        dismissViewControllerAnimated(false, completion: nil)
    }
    
    //MARK: UITextFiealDelegate
    
    @IBAction func searchTextChanged(sender: UITextField) {
        streamView.reload()
    }
    
    func shareContent(wrap: Wrap) {
        if let text = text {
            let controller = WrapViewController(wrap: wrap, segment: .Chat)
            UINavigationController.main.pushViewController(controller, animated: false)
            dismissViewControllerAnimated(false, completion: nil)
            performWhenLoaded(controller.chatViewController, block: { controller in
                Dispatch.mainQueue.async({
                    controller.composeBar.becomeFirstResponder()
                    controller.composeBar.text = text
                })
            })
        } else if let assets = assets {
            let queue = runQueue
            let completionBlock: Block = { [weak self] _ in
                queue.didFinish = nil
                if let weakSelf = self {
                    let controller = UploadSummaryViewController()
                    controller.assets = assets
                    controller.delegate = weakSelf
                    controller.wrap = wrap
                    controller.changeWrap = { _ in self?.navigationController?.popViewControllerAnimated(false) }
                    self?.navigationController?.pushViewController(controller, animated: false)
                }
            }
            if queue.isExecuting {
                let spinner = UIActivityIndicatorView(activityIndicatorStyle: .White)
                navigationBar!.add(spinner, { (make) in
                    make.trailing.equalTo(navigationBar!).offset(-12)
                    make.centerY.equalTo(navigationBar!).offset(10)
                })
                spinner.startAnimating()
                queue.didFinish = {
                    spinner.removeFromSuperview()
                    completionBlock()
                }
            } else {
                completionBlock()
            }
        }
    }
}

extension WrapListViewController: UploadSummaryViewControllerDelegate {
    
    func uploadSummaryViewController(controller: UploadSummaryViewController, didDeselectAsset asset: MutableAsset) {
        if let index = assets?.indexOf(asset) {
            assets?.removeAtIndex(index)
        }
        if assets?.count == 0 {
            dismissViewControllerAnimated(false, completion: nil)
        }
    }
    
    func uploadSummaryViewController(controller: UploadSummaryViewController, didFinishWithAssets assets: [MutableAsset]) {
        dismissViewControllerAnimated(false, completion: nil)
        Sound.play()
        controller.wrap?.uploadAssets(assets)
    }
}

