//
//  WrapSettingsViewController.swift
//  meWrap
//
//  Created by Yura Granchenko on 19/01/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class WrapEditSession: CompoundEditSession {
    
    var name: EditSession<String>
    var isRestrictedInvite: EditSession<Bool>
    
    required init(wrap: Wrap) {
        name = EditSession<String>(originalValue: wrap.name ?? "", setter: { wrap.name = $0 })
        isRestrictedInvite = EditSession<Bool>(originalValue: wrap.isRestrictedInvite, setter: { wrap.isRestrictedInvite = $0 })
        super.init()
        addSession(isRestrictedInvite)
        addSession(name)
    }
}

class WrapNotifyEditSession: CompoundEditSession {
    
    var notifyCandy: EditSession<Bool>
    var notifyComment: EditSession<Bool>
    var notifyChat: EditSession<Bool>
    
    required init(wrap: Wrap) {
        notifyCandy = EditSession<Bool>(originalValue: wrap.isCandyNotifiable, setter: { wrap.isCandyNotifiable = $0 })
        notifyComment = EditSession<Bool>(originalValue: wrap.isCommentNotifiable, setter: { wrap.isCommentNotifiable = $0 })
        notifyChat = EditSession<Bool>(originalValue: wrap.isChatNotifiable, setter: { wrap.isChatNotifiable = $0 })
        super.init()
        addSession(notifyCandy)
        addSession(notifyComment)
        addSession(notifyChat)
    }
    
    func updateWithWrap(wrap: Wrap) {
        notifyCandy.originalValue = wrap.isCandyNotifiable
        notifyComment.originalValue = wrap.isCommentNotifiable
        notifyChat.originalValue = wrap.isChatNotifiable
    }
}

final class WrapSettingsViewController: BaseViewController, EntryNotifying, EditSessionDelegate {
    
    @IBOutlet weak var wrapNameTextField: UITextField!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var candyNotifyTrigger: UISwitch!
    @IBOutlet weak var chatNotifyTrigger: UISwitch!
    @IBOutlet weak var commentNotifyTrigger: UISwitch!
    @IBOutlet weak var restrictedInviteTrigger: UISwitch!
    @IBOutlet weak var adminLabel: UILabel!
    @IBOutlet weak var chatPrioritizer: LayoutPrioritizer!
    
    @IBOutlet weak var saveButton: UIButton!
    
    weak var wrap: Wrap?
    
    private var editSession: WrapEditSession?
    
    private var notifyEditSession: WrapNotifyEditSession?
    
    private var userInitiatedDestructiveAction = false
    
    private var isAdmin = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        saveButton.hidden = true
        guard let wrap = wrap else { return }
        let title = wrap.deletable ? "DELETE_WRAP".ls : (wrap.isPublic ? "FOLLOWING" : "LEAVE_WRAP").ls
        actionButton.setTitle(title, forState: .Normal)
        wrapNameTextField.text = wrap.name
        editSession = WrapEditSession(wrap: wrap)
        editSession?.delegate = self
        notifyEditSession = WrapNotifyEditSession(wrap: wrap)
        notifyEditSession?.delegate = self
        if wrap.isPublic && !(wrap.contributor?.current ?? false)  {
            let isFollowing = wrap.isContributing
            editButton.hidden = isFollowing
            wrapNameTextField.enabled = !isFollowing
        }
        isAdmin = wrap.contributor?.current ?? false && !wrap.isPublic
        restrictedInviteTrigger.hidden = !isAdmin
        if isAdmin {
            adminLabel.text = "allow_friends_to_add_people".ls
        } else {
            adminLabel.text = !wrap.isRestrictedInvite ? "friends_allowed_to_app_people".ls : "only_admin_can_add_people".ls
        }
        chatPrioritizer.defaultState = !wrap.isPublic
        candyNotifyTrigger.on = wrap.isCandyNotifiable
        chatNotifyTrigger.on = wrap.isChatNotifiable
        commentNotifyTrigger.on = wrap.isCommentNotifiable
        restrictedInviteTrigger.on = !wrap.isRestrictedInvite
        APIRequest.preferences(wrap).send({ [weak self] _ in
            self?.candyNotifyTrigger.on = wrap.isCandyNotifiable
            self?.commentNotifyTrigger.on = wrap.isCommentNotifiable
            self?.chatNotifyTrigger.on = wrap.isChatNotifiable
            self?.notifyEditSession?.updateWithWrap(wrap)
            })
        Wrap.notifier().addReceiver(self)
    }
    
    @IBAction func handleAction(sender: Button) {
        guard let wrap = wrap else { return }
        UIAlertController.confirmWrapDeleting(wrap, success: {[weak self] _ in
            self?.userInitiatedDestructiveAction = true
            sender.loading = false
            self?.view.userInteractionEnabled = false
            let deletable = wrap.deletable
            wrap.delete({ _ in
                if (wrap.isPublic) {
                    self?.navigationController?.popViewControllerAnimated(false)
                } else {
                    self?.navigationController?.popToRootViewControllerAnimated(false)
                    if (deletable) { Toast.show("delete_wrap_success".ls) }
                }
                sender.loading = false
                }, failure: { [weak self] error -> Void in
                    self?.userInitiatedDestructiveAction = false
                    error?.show()
                    sender.loading = false
                    self?.view.userInteractionEnabled = true
                })
            }, failure: { _ in })
    }
    
    @IBAction func changeSwichValue(sender: AnyObject) {
        notifyEditSession?.notifyCandy.changedValue = candyNotifyTrigger.on
        notifyEditSession?.notifyChat.changedValue = chatNotifyTrigger.on
        notifyEditSession?.notifyComment.changedValue = commentNotifyTrigger.on
        if isAdmin {
            editSession?.isRestrictedInvite.changedValue = restrictedInviteTrigger.on
        }
    }
    
    @IBAction func editButtonClick(sender: UIButton) {
        if sender.selected {
            editSession?.name.reset()
            wrapNameTextField.resignFirstResponder()
            wrapNameTextField.text = editSession?.name.originalValue
        } else {
            wrapNameTextField.becomeFirstResponder()
        }
    }
    
    //MARK: UITextFieldHandler
    
    @IBAction func textFieldEditChange(textfield: UITextField) {
        if let text = textfield.text where text.characters.count > Constants.wrapNameLimit {
            textfield.text = text.substringToIndex(text.startIndex.advancedBy(Constants.wrapNameLimit))
        }
        editSession?.name.changedValue = textfield.text?.trim ?? ""
        editButton.selected = editSession?.hasChanges ?? false
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func save(sender: AnyObject) {
        if let wrap = wrap {
            if let name = wrapNameTextField.text?.trim where !name.isEmpty {
                if let editSession = editSession where editSession.hasChanges == true {
                    editSession.apply()
                    wrap.update({ _ in }, failure: { error in
                        error?.show()
                        editSession.reset()
                    })
                }
                if let editSession = notifyEditSession where editSession.hasChanges == true {
                    editSession.apply()
                    APIRequest.changePreferences(wrap).send({ _ in }, failure: { error in
                        error?.show()
                        editSession.reset()
                    })
                }
            } else {
                Toast.show("wrap_name_cannot_be_blank".ls)
            }
        }
        navigationController?.popViewControllerAnimated(false)
    }
    
    //MARK: EntryNotifying
    
    func notifier(notifier: EntryNotifier, willDeleteEntry entry: Entry) {
        if let wrap = entry as? Wrap where viewAppeared && !userInitiatedDestructiveAction {
            navigationController?.popToRootViewControllerAnimated(false)
            if !wrap.deletable {
                Toast.showMessageForUnavailableWrap(wrap)
            }
        }
    }
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        if let wrap = entry as? Wrap where isAdmin {
            adminLabel.text = !wrap.isRestrictedInvite ? "friends_allowed_to_app_people".ls : "only_admin_can_add_people".ls
        }
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return wrap == entry
    }
    
    func editSession(session: EditSessionProtocol, hasChanges: Bool) {
        saveButton.hidden = editSession?.hasChanges == false && notifyEditSession?.hasChanges == false
    }
}
