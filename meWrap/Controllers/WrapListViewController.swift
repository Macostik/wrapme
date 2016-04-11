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
    
    private var runQueue = RunQueue(limit: 1)
    private var content = [String]()
    private var assets = [MutableAsset]()
    private var textFile = NSURL()
    
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
        extractConent()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        spinner.hidden = true
    }
    
    func extractConent() {
        let manager = NSFileManager.defaultManager()
        if manager.fileExistsAtPath(url.path!) {
            guard let files = try? manager.contentsOfDirectoryAtPath(url.path!) else { return }
            var map = [String: String]()
            for file in files {
                let timeInterval = file.subString("_", secondCharacter: ".") ?? ""
                map[timeInterval] = file
            }
            let sortedKeys = map.keys.sort()
            content = sortedKeys.map({ map[$0]!})
        }
        if content.first?.hasSuffix("txt") != true {
            if content.count <= 10 {
                handleAssets()
            } else {
                InfoToast.show("upload_photos_limit_error".ls)
                while content.count > 10 {
                    content.removeLast()
                }
                handleAssets()
            }
        } else {
            textFile = url.URLByAppendingPathComponent(content.first ?? "")
        }
    }
    
    func handleAssets() {
        for file in content {
            guard let path = url.URLByAppendingPathComponent(file).path else { break }
            guard let data = NSFileManager.defaultManager().contentsAtPath(path) else { break }
            let asset = MutableAsset()
            asset.date = NSDate.now()
            assets.append(asset)
            if file.hasSuffix("jpeg") {
                guard let image = UIImage(data: data) else { return }
                asset.type = .Photo
                runQueue.run({ finish in
                    asset.setImage(image, completion:finish)
                })
            } else if file.hasSuffix("mov")  {
                asset.type = .Video
                runQueue.run({ finish in
                    asset.setVideoFromRecordAtPath(path, completion: finish)
                })
            } else if file.hasSuffix("mp4") {
                asset.type = .Video
                runQueue.run({ finish in
                    asset.setVideoAtPath(path, completion: finish)
                })
            }
        }
    }
    
    @IBAction func cancel(sender: AnyObject?) {
        self.navigationController?.popViewControllerAnimated(false)
    }
    
    //MARK: UITextFiealDelegate
    
    @IBAction func searchTextChanged(sender: UITextField) {
        streamView.reload()
    }
    
    func shareContent(wrap: Wrap) {
        if !textFile.absoluteString.isEmpty {
            guard let data = NSFileManager.defaultManager().contentsAtPath(textFile.path!) else { return }
            guard let text = String(data: data, encoding: NSUTF8StringEncoding) else { return }
            let controller = Storyboard.Wrap.instantiate()
            controller.segment = .Chat
            controller.wrap = wrap
            self.navigationController?.pushViewController(controller, animated: false)
            performWhenLoaded(controller, block: { controller in
                Dispatch.mainQueue.async({
                    guard case let chatViewController = controller.chatViewController
                            where chatViewController.isViewLoaded() == true  else { return }
                    chatViewController.composeBar.becomeFirstResponder()
                    chatViewController.composeBar.text = text
                })
            })
        } else {
            let queue = runQueue
            let completionBlock: Block = { [weak self] _ in
                queue.didFinish = nil
                if let weakSelf = self {
                    guard let assets = self?.assets else { return }
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

extension String {
    func subString(firstCharacter: String, secondCharacter: String, options mask: NSStringCompareOptions = .CaseInsensitiveSearch) -> String? {
        if let startIndex = self.rangeOfString(firstCharacter, options: mask, range: nil, locale: nil)?.endIndex {
            if let endIndex = self.rangeOfString(secondCharacter, options: mask, range: nil, locale: nil)?.startIndex where endIndex > startIndex {
                return self[Range(startIndex ..< endIndex)]
            }
        }
        return nil
    }
}

