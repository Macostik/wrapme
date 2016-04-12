//
//  WrapListViewController.swift
//  meWrap
//
//  Created by Yura Granchenko on 25/02/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class WrapListViewController: BaseViewController {
    
    static var isWrapListPresented = false
    
    var items: [[String:String]]?
    
    private var runQueue = RunQueue(limit: 1)
    private var assets: [MutableAsset]?
    private var text: String?
    
    private lazy var url: NSURL = {
        guard var url = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(Constants.groupIdentifier) else { return NSURL(fileURLWithPath: "") }
        return url.URLByAppendingPathComponent("ShareExtension/")
    }()
    
    @IBOutlet var wrapListDataSource: PaginatedStreamDataSource!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var streamView: StreamView!
    @IBOutlet weak var searchField: TextField!
    
    deinit {
        WrapListViewController.isWrapListPresented = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        WrapListViewController.isWrapListPresented = true
        wrapListDataSource.placeholderMetrics = StreamMetrics(loader: PlaceholderView.sharePlaceholderLoader())
        
        let metrics = wrapListDataSource.addMetrics(StreamMetrics(loader: StreamLoader<WrapCell>(), size: 70))
        metrics.modifyItem = { [weak self] item in
            let wrap = item.entry as! Wrap
            if let text = self?.searchField?.text where !text.isEmpty {
                item.hidden = wrap.name?.rangeOfString(text, options: .CaseInsensitiveSearch, range: nil, locale: nil) == nil
            } else {
                item.hidden = false
            }
        }
        metrics.selection = { [weak self] item, entry in
            self?.shareContent(entry as! Wrap)
        }
        wrapListDataSource.items = PaginatedList(entries:User.currentUser?.sortedWraps ?? [], request:PaginatedRequest.wraps(nil))
        extractContent()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        spinner.hidden = true
    }
    
    func extractContent() {
        if let items = items?.sort({ $0["createdAt"] < $1["createdAt"] }) {
            if let text = items.filter({ $0["type"] == "text" }).first {
                let textFile = url.URLByAppendingPathComponent(text["fileName"] ?? "")
                guard let data = NSData(contentsOfURL: textFile) else { return }
                self.text = String(data: data, encoding: NSUTF8StringEncoding)
            } else {
                if items.count <= 10 {
                    assets = handleAssets(items)
                } else {
                    InfoToast.show("upload_photos_limit_error".ls)
                    handleAssets(Array(items.prefix(10)))
                }
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
        self.navigationController?.popViewControllerAnimated(false)
    }
    
    //MARK: UITextFiealDelegate
    
    @IBAction func searchTextChanged(sender: UITextField) {
        streamView.reload()
    }
    
    func shareContent(wrap: Wrap) {
        if let text = text {
            let controller = Storyboard.Wrap.instantiate()
            controller.segment = .Chat
            controller.wrap = wrap
            self.navigationController?.pushViewController(controller, animated: false)
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
                    Storyboard.UploadSummary.instantiate({
                        $0.assets = assets
                        $0.delegate = weakSelf
                        $0.wrap = wrap
                        $0.changeWrap = { _ in self?.navigationController?.popViewControllerAnimated(false) }
                        self?.navigationController?.pushViewController($0, animated: false)
                    })
                }
            }
            if queue.isExecuting {
                spinner.hidden = false
                spinner.startAnimating()
                queue.didFinish = { [weak self] in
                    self?.spinner.stopAnimating()
                    completionBlock()
                }
            } else {
                completionBlock()
            }
        }
    }
}

extension WrapListViewController: UploadSummaryViewControllerDelegate {
    
    func uploadSummaryViewController(controller: UploadSummaryViewController, didDeselectAsset asset: MutableAsset) {}
    
    func uploadSummaryViewController(controller: UploadSummaryViewController, didFinishWithAssets assets: [MutableAsset]) {
        self.navigationController?.popToRootViewControllerAnimated(false)
        Sound.play()
        controller.wrap?.uploadAssets(assets)
    }
}

