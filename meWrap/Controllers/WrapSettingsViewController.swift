//
//  WrapSettingsViewController.swift
//  meWrap
//
//  Created by Yura Granchenko on 19/01/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class WrapSettingsViewController: WLBaseViewController, EntryNotifying {
    
    @IBOutlet weak var wrapNameTextField: UITextField!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var candyNotifyTrigger: UISwitch!
    @IBOutlet weak var chatNotifyTrigger: UISwitch!
    @IBOutlet weak var restrictedInviteTrigger: UISwitch!
    @IBOutlet weak var adminLabel: UILabel!
    @IBOutlet weak var chatPrioritizer: LayoutPrioritizer!
    
    weak var wrap: Wrap?
    lazy var runQueue: RunQueue = RunQueue(limit: 1)
    var editSession: EditSession<String>?
    var userInitiatedDestructiveAction = false
    var isAdmin = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let wrap = wrap else { return }
        let title = wrap.deletable ? "DELETE_WRAP".ls : (wrap.isPublic ? "FOLLOWING" : "LEAVE_WRAP").ls
        actionButton.setTitle(title, forState: .Normal)
        wrapNameTextField.text = wrap.name
        editSession = EditSession<String>(originalValue: wrap.name ?? "", setter: { wrap.name = $0 })
        if wrap.isPublic && !(wrap.contributor?.current ?? false)  {
            let isFollowing = wrap.isContributing
            editButton.hidden = isFollowing
            wrapNameTextField.enabled = !isFollowing
        }
        isAdmin = wrap.contributor?.current ?? false && !wrap.isPublic
        restrictedInviteTrigger.hidden = !isAdmin
        if (isAdmin) {
            adminLabel.text = "allow_friends_to_add_people".ls
        } else {
            adminLabel.text = !wrap.isRestrictedInvite ? "friends_allowed_to_app_people".ls : "only_admin_can_add_people".ls
        }
        chatPrioritizer.defaultState = !wrap.isPublic
        
        candyNotifyTrigger.on = wrap.isCandyNotifiable
        chatNotifyTrigger.on = wrap.isChatNotifiable
        restrictedInviteTrigger.on = !wrap.isRestrictedInvite
        candyNotifyTrigger.userInteractionEnabled = false
        chatNotifyTrigger.userInteractionEnabled = false
        
        APIRequest.preferences(wrap).send({[weak self] wrap -> Void in
            if let wrap = wrap {
                self?.candyNotifyTrigger.on = wrap.isCandyNotifiable
                self?.chatNotifyTrigger.on = wrap.isChatNotifiable
                self?.candyNotifyTrigger.userInteractionEnabled = true
                self?.chatNotifyTrigger.userInteractionEnabled = true
            }
            }) {[weak self] error -> Void in
                self?.candyNotifyTrigger.userInteractionEnabled = true
                self?.chatNotifyTrigger.userInteractionEnabled = true
        }
        Wrap.notifier().addReceiver(self)
    }

    @IBAction func handleAction(sender: Button) {
        guard  let wrap = wrap else { return }
        UIAlertController.confirmWrapDeleting(wrap, success: {[weak self] _ in
            self?.userInitiatedDestructiveAction = true
            sender.loading = false
            self?.view.userInteractionEnabled = false
            let deletable = wrap.deletable
            wrap.delete({[weak self] _ in
                if (wrap.isPublic) {
                    self?.navigationController?.popViewControllerAnimated(false)
                } else {
                    self?.navigationController?.popToRootViewControllerAnimated(false)
                    if  (deletable) { Toast.show("delete_wrap_success".ls) }
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
        self.enqueueSelector("performUploadPreferenceRequest", delay: 1.0)
    }
    
    @IBAction func editButtonClick(sender: UIButton) {
        if (sender.selected) {
            editSession?.reset()
            wrapNameTextField.resignFirstResponder()
            wrapNameTextField.text = editSession?.originalValue
        } else {
            wrapNameTextField.becomeFirstResponder()
        }
    }
    
    //MARK: UITextFieldHandler
    
    @IBAction func textFieldEditChange(textfield: UITextField) {
        if (textfield.text?.characters.count > Constants.wrapNameLimit) {
            var text = textfield.text
            if let index = text?.startIndex.advancedBy(Constants.wrapNameLimit) {
                text = text?.substringToIndex(index)
            }
        }
        editSession?.changedValue = textfield.text?.trim ?? ""
        editButton.selected = editSession?.hasChanges ?? false
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        guard let wrap = wrap else {  return false }
        if let name = textField.text?.trim where !name.isEmpty {
            if editSession?.hasChanges == true {
                editSession?.apply()
                wrap.update({ [weak self] _ in
                    self?.editButton.selected = false
                    }, failure: { [weak self] error in
                        error?.show()
                        self?.editSession?.reset()
                })
            }
        } else {
            Toast.show("wrap_name_cannot_be_blank".ls)
            wrapNameTextField.text = editSession?.originalValue
        }
        editButton.selected = false
        textField.resignFirstResponder()
   
        return true
    }
    
    @IBAction override func back(sender: UIButton) {
        self.textFieldShouldReturn(wrapNameTextField)
        navigationController?.popViewControllerAnimated(false)
    }
    
    @IBAction func handleFriendsInvite(sender: UISwitch) {
        if let wrap = wrap {
            sender.userInteractionEnabled = false
            wrap.isRestrictedInvite = !sender.on
            wrap.update({ (wrap) -> Void in
                if let wrap = wrap {
                    sender.on = !wrap.isRestrictedInvite
                    sender.userInteractionEnabled = true
                }
                }, failure: { _ in
                    sender.userInteractionEnabled = true
            })
        }
    }
    
    func performUploadPreferenceRequest() {
        let candyNotify = candyNotifyTrigger.on
        let chatNotify = chatNotifyTrigger.on
        if let wrap = wrap {
            runQueue.run({ finish -> Void in
                let _candyNotify = wrap.isCandyNotifiable
                let _chatNotify = wrap.isChatNotifiable
                wrap.isCandyNotifiable = candyNotify
                wrap.isChatNotifiable = chatNotify
                APIRequest.changePreferences(wrap).send({ _ in
                    finish()
                    }, failure: { [weak self] _ in
                        finish()
                        self?.candyNotifyTrigger.on = _candyNotify
                        wrap.isCandyNotifiable =      _candyNotify
                        self?.chatNotifyTrigger.on =  _chatNotify
                        wrap.isChatNotifiable =       _chatNotify
                    })
            })
        }
    }
    
    //MARK: EntryNotifying
    
    func notifier(notifier: EntryNotifier, willDeleteEntry entry: Entry) {
        if let wrap = entry as? Wrap {
            if (viewAppeared && !self.userInitiatedDestructiveAction) {
                navigationController?.popToRootViewControllerAnimated(false)
                if (!wrap.deletable) {
                    Toast.showMessageForUnavailableWrap(wrap)
                }
            }
        }
    }
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
         if let wrap = entry as? Wrap {
            if (!isAdmin) {
                adminLabel.text = !wrap.isRestrictedInvite ? "friends_allowed_to_app_people".ls : "only_admin_can_add_people".ls
            }
        }
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return wrap == entry
    }
}
