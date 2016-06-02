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

class WrapPickerDataSource: StreamDataSource<[Wrap]> {
    
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

class WrapPickerCell: EntryStreamReusableView<Wrap> {
    
    private let coverView = ImageView(backgroundColor: UIColor.clearColor(), placeholder: ImageView.Placeholder.gray.photoStyle(24))
    private let nameLabel = Label(preset: .Normal, textColor: Color.grayDarker)
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        coverView.cornerRadius = 16
        add(coverView) {
            $0.centerX.equalTo(self).offset(-120)
            $0.centerY.equalTo(self)
            $0.size.equalTo(36)
        }
        
        add(nameLabel) {
            $0.leading.equalTo(coverView.snp_trailing).offset(12)
            $0.centerY.equalTo(self)
            $0.width.equalTo(240)
        }
        
        add(SeparatorView(color: Color.grayDarker.colorWithAlphaComponent(0.1))) {
            $0.leading.trailing.bottom.equalTo(self)
            $0.height.equalTo(1)
        }
    }
    
    override func setup(wrap: Wrap) {
        coverView.url = wrap.asset?.small
        nameLabel.text = wrap.name
    }
}

class WrapPickerViewController: BaseViewController {

    weak var delegate: WrapPickerViewControllerDelegate?
    
    weak var wrap: Wrap?
    
    private let streamView = StreamView()
    
    private lazy var dataSource: WrapPickerDataSource = WrapPickerDataSource(streamView: self.streamView)
    
    private let wrapNameTextField = TextField()
    private let creationView = UIView()
    private let createButton = Button(icon: "P", size: 36, textColor: Color.grayDark)
    private let saveButton = Button(icon: "N", size: 36, textColor: Color.grayDark)
    
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
    
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = UIColor(white: 0, alpha: 0.5)
        
        let gestureView = UIView()
        gestureView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.hide(_:))))
        view.add(gestureView) { (make) in
            make.edges.equalTo(view)
        }
        
        streamView.cornerRadius = 6
        streamView.backgroundColor = Color.grayLightest.colorWithAlphaComponent(0.84)
        view.add(streamView) { (make) in
            make.centerY.equalTo(view)
            make.trailing.leading.equalTo(view).inset(10)
            make.height.equalTo(165)
        }
        
        creationView.clipsToBounds = true
        
        streamView.add(creationView) { (make) in
            make.centerX.top.equalTo(streamView)
            make.size.equalTo(CGSize(width: 300, height: 55))
        }
        
        createButton.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        createButton.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        saveButton.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        saveButton.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        createButton.addTarget(self, touchUpInside: #selector(self.createNewWrap(_:)))
        creationView.add(createButton) { (make) in
            make.centerY.equalTo(creationView)
            make.leading.equalTo(creationView).inset(12)
        }
        
        wrapNameTextField.delegate = self
        wrapNameTextField.disableSeparator = true
        wrapNameTextField.trim = true
        wrapNameTextField.font = Font.Normal + .Light
        wrapNameTextField.makePresetable(.Normal)
        
        creationView.addSubview(saveButton)
        
        creationView.add(wrapNameTextField) { (make) in
            make.leading.equalTo(createButton.snp_trailing).offset(12)
            make.centerY.equalTo(creationView)
            make.height.equalTo(44)
            make.trailing.equalTo(saveButton.snp_leading).offset(-12)
        }
        
        saveButton.addTarget(self, touchUpInside: #selector(self.saveNewWrap(_:)))
        if wrap == nil {
            setCreating(true, animated: false)
            Dispatch.mainQueue.async { self.wrapNameTextField.becomeFirstResponder() }
        } else {
            setCreating(false, animated: false)
        }
        
        dataSource.layoutOffset = ItemHeight
        streamView.contentInset = UIEdgeInsetsMake(ItemHeight, 0, ItemHeight, 0)
        streamView.scrollIndicatorInsets = streamView.contentInset
        
        let metrics = dataSource.addMetrics(StreamMetrics<WrapPickerCell>(size: ItemHeight))
        metrics.selection = { [weak self] view in
            if let weakSelf = self {
                if let index = view.item?.position.index where weakSelf.streamView.contentOffset.y != CGFloat(index) * ItemHeight {
                    weakSelf.streamView.setContentOffset(0 ^ CGFloat(index) * CGFloat(ItemHeight), animated: true)
                } else {
                    Dispatch.mainQueue.async {
                        weakSelf.delegate?.wrapPickerViewControllerDidFinish(weakSelf)
                    }
                }
            }
        }
        
        wraps = User.currentUser?.sortedWraps
        
        if let wrap = wrap, let index = wraps?.indexOf(wrap) {
            streamView.setContentOffset(0 ^ CGFloat(index) * ItemHeight, animated: true)
        }
        
        view.addGestureRecognizer(streamView.panGestureRecognizer)
        streamView.addObserver(self, forKeyPath: "contentOffset", options: .New, context: nil)
        
        wrapNameTextField.placeholder = "new_wrap".ls
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
    
    override func keyboardAdjustmentConstant(adjustment: KeyboardAdjustment, keyboard: Keyboard) -> CGFloat {
        return max(0, keyboard.height - (view.height - streamView.frame.maxY - 10))
    }
    
    func showInViewController(controller: UIViewController) {
        controller.addContainedViewController(self, animated: false)
    }
    
    func hide() {
        view.endEditing(true)
        removeFromContainerAnimated(false)
    }
    
    private var creating: Bool?
    
    func setCreating(creating: Bool, animated: Bool) {
        guard creating != self.creating else { return }
        self.creating = creating
        animate(animated) {
            saveButton.snp_remakeConstraints { (make) in
                if creating {
                    make.centerY.equalTo(creationView)
                    make.trailing.equalTo(creationView).inset(12)
                } else {
                    make.centerY.equalTo(creationView)
                    make.leading.equalTo(creationView.snp_trailing)
                }
            }
            if animated {
                saveButton.superview?.layoutIfNeeded()
            }
        }
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
        wrapNameTextField.becomeFirstResponder()
    }
    
    @IBAction func saveNewWrap(sender: Button) {
        
        guard let name = wrapNameTextField.text?.trim where name.isEmpty == false else {
            Toast.show("wrap_name_cannot_be_blank".ls)
            return
        }
        
        wrapNameTextField.resignFirstResponder()
        
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
        if wrapNameTextField.isFirstResponder() == true {
            wrapNameTextField.resignFirstResponder()
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
        wrapNameTextField.placeholder = "what_is_new_wrap_about".ls
        setCreating(true, animated: true)
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        wrapNameTextField.placeholder = "new_wrap".ls
        setCreating(false, animated: true)
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
