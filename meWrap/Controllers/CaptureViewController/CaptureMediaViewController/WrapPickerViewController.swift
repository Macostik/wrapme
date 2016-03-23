//
//  WrapPickerViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/30/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit

private let ItemHeight: CGFloat = 55

class WrapPickerDataSource: StreamDataSource {
    
    var didEndScrollingAnimationBlock: (Void -> Void)?
    
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        targetContentOffset.memory.y = round(targetContentOffset.memory.y / ItemHeight) * ItemHeight
    }
    
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        if let block = didEndScrollingAnimationBlock {
            block()
            didEndScrollingAnimationBlock = nil
        }
    }
}

protocol WrapPickerViewControllerDelegate: class {
    func wrapPickerViewController(controller: WrapPickerViewController, didCreateWrap wrap: Wrap)
    func wrapPickerViewController(controller: WrapPickerViewController, didSelectWrap wrap: Wrap)
    func wrapPickerViewControllerDidFinish(controller: WrapPickerViewController)
    func wrapPickerViewControllerDidCancel(controller: WrapPickerViewController)
}

class WrapPickerCell: StreamReusableView {
    
    weak var coverView: WrapCoverView?
    weak var nameLabel: UILabel?
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        let coverView = WrapCoverView()
        coverView.contentMode = .ScaleAspectFill
        coverView.clipsToBounds = true
        coverView.cornerRadius = 16
        coverView.defaultBackgroundColor = Color.grayLighter
        coverView.defaultIconColor = UIColor.whiteColor()
        coverView.defaultIconText = "t"
        addSubview(coverView)
        self.coverView = coverView
        
        let nameLabel = Label(preset: .Normal, weight: UIFontWeightLight, textColor: Color.grayDarker)
        addSubview(nameLabel)
        self.nameLabel = nameLabel
        
        let separator = SeparatorView(color: Color.grayDarker.colorWithAlphaComponent(0.1))
        addSubview(separator)
        
        coverView.snp_makeConstraints(closure: {
            $0.centerX.equalTo(self).offset(-120)
            $0.centerY.equalTo(self)
            $0.width.height.equalTo(36)
        })
        
        nameLabel.snp_makeConstraints(closure: {
            $0.leading.equalTo(coverView.snp_trailing).offset(12)
            $0.centerY.equalTo(self)
            $0.width.equalTo(240)
        })
        
        separator.snp_makeConstraints(closure: {
            $0.leading.trailing.bottom.equalTo(self)
            $0.height.equalTo(1)
        })
    }
    
    override func setup(entry: AnyObject?) {
        if let wrap = entry as? Wrap {
            if let coverView = coverView {
                coverView.url = wrap.asset?.small
                coverView.isFollowed = wrap.isPublic ? wrap.isContributing : false
                coverView.isOwner = wrap.isPublic ? (wrap.contributor?.current ?? false) : false
            }
            nameLabel?.text = wrap.name;
        }
    }
}

class WrapPickerViewController: BaseViewController {

    weak var delegate: WrapPickerViewControllerDelegate?
    
    weak var wrap: Wrap?
    
    @IBOutlet weak var streamView: StreamView!
    
    lazy var dataSource: WrapPickerDataSource = WrapPickerDataSource(streamView: self.streamView)
    
    @IBOutlet weak var wrapNameTextField: UITextField?
    
    @IBOutlet var editingPrioritizer: LayoutPrioritizer?
    
    private var wraps: [Wrap]? {
        didSet {
            dataSource.items = wraps
        }
    }
    
    deinit {
        streamView.removeObserver(self, forKeyPath: "contentOffset", context: nil)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Slide
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource.layoutOffset = ItemHeight
        streamView.contentInset = UIEdgeInsetsMake(ItemHeight, 0, ItemHeight, 0)
        streamView.scrollIndicatorInsets = streamView.contentInset
        
        let metrics = dataSource.addMetrics(StreamMetrics(loader: StreamLoader<WrapPickerCell>(), size: ItemHeight))
        metrics.selection = { [weak self] item, entry in
            if let weakSelf = self {
                if let index = item?.position.index where weakSelf.streamView.contentOffset.y != CGFloat(index) * CGFloat(ItemHeight) {
                    weakSelf.streamView.setContentOffset(CGPoint(x: 0, y: CGFloat(index) * CGFloat(ItemHeight)), animated: true)
                } else {
                    Dispatch.mainQueue.async {
                        weakSelf.delegate?.wrapPickerViewControllerDidFinish(weakSelf)
                    }
                }
            }
        }
        
        wraps = User.currentUser?.sortedWraps
        
        if let wrap = wrap, let index = wraps?.indexOf(wrap) {
            streamView.setContentOffset(CGPoint(x: 0, y: CGFloat(index) * CGFloat(ItemHeight)), animated: true)
        }
        
        view.addGestureRecognizer(streamView.panGestureRecognizer)
        streamView.addObserver(self, forKeyPath: "contentOffset", options: .New, context: nil)
        
        wrapNameTextField?.placeholder = "new_wrap".ls
        if wrap == nil {
            editingPrioritizer?.defaultState = true
            Dispatch.mainQueue.async { self.wrapNameTextField?.becomeFirstResponder() }
        }
        Wrap.notifier().addReceiver(self)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        let offset = streamView.contentOffset.y
        if wraps?.count > 0 && offset >= 0 {
            let index = Int(round(offset / ItemHeight))
            if let wrap = wraps?[safe: index] where wrap != self.wrap {
                self.wrap = wrap
                delegate?.wrapPickerViewController(self, didSelectWrap: wrap)
            }
        }
    }
    
    override func constantForKeyboardAdjustmentBottomConstraint(constraint: NSLayoutConstraint, defaultConstant: CGFloat, keyboardHeight: CGFloat) -> CGFloat {
        return max(0, keyboardHeight - (view.height - streamView.frame.maxY - 10))
    }
    
    func showInViewController(controller: UIViewController) {
        controller.addContainedViewController(self, animated: false)
    }
    
    func hide() {
        view.endEditing(true)
        removeFromContainerAnimated(false)
    }
}

extension WrapPickerViewController: EntryNotifying {
    
    func notifier(notifier: EntryNotifier, didAddEntry entry: Entry) {
        wraps = User.currentUser?.sortedWraps
    }
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        wraps = User.currentUser?.sortedWraps
    }
    
    func notifier(notifier: EntryNotifier, willDeleteEntry entry: Entry) {
        if let wrap = entry as? Wrap {
            wraps = wraps?.filter({ $0 != wrap })
        }
    }
}

extension WrapPickerViewController {
    
    @IBAction func createNewWrap(sender: AnyObject?) {
        wrapNameTextField?.becomeFirstResponder()
    }
    
    @IBAction func saveNewWrap(sender: Button) {
        
        guard let name = wrapNameTextField?.text?.trim where name.isEmpty == false else {
            Toast.show("wrap_name_cannot_be_blank".ls)
            return
        }
        
        wrapNameTextField?.resignFirstResponder()
        
        let wrap = Wrap.wrap()
        wrap.name = name
        delegate?.wrapPickerViewController(self, didSelectWrap:wrap)
        delegate?.wrapPickerViewController(self, didCreateWrap:wrap)
        delegate?.wrapPickerViewControllerDidFinish(self)
        Uploader.wrapUploader.upload(Uploading.uploading(wrap), success: nil) { (error) -> Void in
            if let error = error where !error.isNetworkError {
                error.show()
                wrap.remove()
            }
        }
        wrap.notifyOnAddition()
    }
    
    @IBAction func hide(sender: AnyObject?) {
        if wrapNameTextField?.isFirstResponder() == true {
            wrapNameTextField?.resignFirstResponder()
        } else {
            delegate?.wrapPickerViewControllerDidCancel(self)
        }
    }
}

extension WrapPickerViewController: UITextFieldDelegate {
    
    @IBAction func textFieldDidChange(textField: UITextField) {
        let text = textField.text ?? ""
        if text.characters.count > Constants.profileNameLimit {
            textField.text = text.substringToIndex(text.startIndex.advancedBy(Constants.profileNameLimit))
        }
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        wrapNameTextField?.placeholder = "what_is_new_wrap_about".ls
        editingPrioritizer?.setDefaultState(false, animated: true)
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        wrapNameTextField?.placeholder = "new_wrap".ls
        editingPrioritizer?.setDefaultState(true, animated: true)
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        let shouldBeginEditing = streamView.contentOffset.y == -ItemHeight
        if !shouldBeginEditing {
            dataSource.didEndScrollingAnimationBlock = { [weak textField] _ in
                textField?.becomeFirstResponder()
            }
            streamView.setContentOffset(CGPoint(x: 0, y: -ItemHeight), animated: true)
        }
        return shouldBeginEditing
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
