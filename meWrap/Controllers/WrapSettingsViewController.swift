//
//  WrapSettingsViewController.swift
//  meWrap
//
//  Created by Yura Granchenko on 19/01/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class WrapEditSession: CompoundEditSession {
    
    let name: EditSession<String>
    let restricted: EditSession<Bool>
    let muted: EditSession<Bool>
    
    required init(wrap: Wrap) {
        name = EditSession<String>(originalValue: wrap.name ?? "", setter: { wrap.name = $0 })
        restricted = EditSession<Bool>(originalValue: wrap.restricted, setter: { wrap.restricted = $0 })
        muted = EditSession<Bool>(originalValue: wrap.muted, setter: { wrap.muted = $0 })
        super.init()
        addSession(restricted)
        addSession(name)
        addSession(muted)
    }
}

final class WrapSettingsViewController: BaseViewController, EntryNotifying, EditSessionDelegate, UITextFieldDelegate {
    
    private let nameField = TextField()
    private let editButton = Button(icon: "<", size: 20, textColor: Color.grayLighter)
    private let actionButton = Button(preset: .Small, weight: .Regular, textColor: Color.orange)
    private let muteSwitch = UISwitch()
    private let restrictSwitch = UISwitch()
    private let restrictLabel = Label(preset: .Small, weight: .Light, textColor: Color.grayLighter)
    
    private let saveButton = Button(icon: "E", size: 28, textColor: .whiteColor())
    
    private let editSession: WrapEditSession
    
    let wrap: Wrap
    
    private let isAdmin: Bool
    
    required init(wrap: Wrap) {
        self.wrap = wrap
        editSession = WrapEditSession(wrap: wrap)
        isAdmin = wrap.contributor?.current ?? false
        super.init(nibName: nil, bundle: nil)
        editSession.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var userInitiatedDestructiveAction = false
    
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = .whiteColor()
        
        let navigationBar = UIView()
        
        view.add(navigationBar) { (make) in
            make.leading.top.trailing.equalTo(view)
            make.height.equalTo(64)
        }
        
        navigationBar.backgroundColor = Color.orange
        navigationBar.add(backButton(UIColor.whiteColor())) { (make) in
            make.leading.equalTo(navigationBar).inset(12)
            make.centerY.equalTo(navigationBar).offset(10)
        }
        let title = Label(preset: .Large, weight: .Regular, textColor: UIColor.whiteColor())
        title.text = "settings".ls
        navigationBar.add(title) { (make) in
            make.centerX.equalTo(navigationBar)
            make.centerY.equalTo(navigationBar).offset(10)
        }
        
        navigationBar.add(saveButton) { (make) in
            make.centerY.equalTo(navigationBar).offset(10)
            make.trailing.equalTo(navigationBar).offset(-12)
        }
        
        self.navigationBar = navigationBar
        
        if !wrap.p2p {
            let nameLabel = Label(preset: .Normal, weight: .Regular, textColor: Color.orange)
            nameLabel.text = "title".ls
            view.add(nameLabel) { (make) in
                make.top.equalTo(navigationBar.snp_bottom).offset(12)
                make.leading.equalTo(view).offset(12)
            }
            
            nameField.disableSeparator = true
            nameField.font = Font.Normal + .Regular
            nameField.makePresetable(.Normal)
            nameField.textColor = Color.grayDark
            nameField.placeholder = "wrap_name_cannot_be_blank".ls
            nameField.delegate = self
            nameField.returnKeyType = .Done
            view.add(nameField) { (make) in
                make.top.equalTo(nameLabel.snp_bottom)
                make.leading.equalTo(view).offset(12)
                make.trailing.equalTo(view).offset(-12)
                make.height.equalTo(44)
            }
            
            editButton.setTitleColor(Color.grayDarker, forState: .Highlighted)
            editButton.setTitle("!", forState: .Selected)
            editButton.frame.size = 44 ^ 44
            nameField.rightView = editButton
            nameField.rightViewMode = .Always
            
            let friendsLabel = Label(preset: .Normal, weight: .Regular, textColor: Color.orange)
            friendsLabel.text = "friends".ls
            view.add(friendsLabel) { (make) in
                make.top.equalTo(nameField.snp_bottom).offset(12)
                make.leading.equalTo(view).offset(12)
            }
            
            if isAdmin {
                restrictLabel.text = "allow_friends_to_add_people".ls
            } else {
                restrictLabel.text = wrap.restricted ? "only_admin_can_add_people".ls : "friends_allowed_to_app_people".ls
            }
            restrictLabel.numberOfLines = 0
            view.add(restrictLabel) { (make) in
                make.top.equalTo(friendsLabel.snp_bottom).offset(12)
                make.leading.equalTo(view).offset(12)
                if !isAdmin {
                    make.trailing.equalTo(view).offset(-12)
                }
            }
            
            if isAdmin {
                view.add(restrictSwitch) { (make) in
                    make.centerY.equalTo(restrictLabel)
                    make.trailing.equalTo(view).offset(-12)
                    make.leading.equalTo(restrictLabel.snp_trailing).offset(12)
                }
            }
        }
        
        let notificationsLabel = Label(preset: .Normal, weight: .Regular, textColor: Color.orange)
        notificationsLabel.text = "notifications".ls
        view.add(notificationsLabel) { (make) in
            if wrap.p2p {
                make.top.equalTo(navigationBar.snp_bottom).offset(12)
            } else {
                make.top.equalTo(restrictLabel.snp_bottom).offset(12)
            }
            make.leading.equalTo(view).offset(12)
        }
        
        let muteLabel = Label(preset: .Small, weight: .Regular, textColor: Color.grayDark)
        muteLabel.text = "mute".ls
        muteLabel.numberOfLines = 0
        view.add(muteLabel) { (make) in
            make.top.equalTo(notificationsLabel.snp_bottom).offset(12)
            make.leading.equalTo(view).offset(12)
        }
        
        view.add(muteSwitch) { (make) in
            make.centerY.equalTo(muteLabel)
            make.trailing.equalTo(view).offset(-12)
            make.leading.equalTo(muteLabel.snp_trailing).offset(12)
        }
        
        if !wrap.p2p {
            actionButton.setBorder(color: Color.orange, width: 1)
            actionButton.cornerRadius = 5
            actionButton.clipsToBounds = true
            actionButton.normalColor = .whiteColor()
            actionButton.highlightedColor = Color.orange
            actionButton.setTitleColor(.whiteColor(), forState: .Highlighted)
            actionButton.setTitle(isAdmin ? "DELETE_WRAP".ls : "EXIT_WRAP".ls, forState: .Normal)
            view.add(actionButton) { (make) in
                make.top.equalTo(muteSwitch.snp_bottom).offset(20)
                make.leading.equalTo(view).offset(12)
                make.trailing.equalTo(view).offset(-12)
                make.height.equalTo(30)
            }
            actionButton.addTarget(self, touchUpInside: #selector(self.handleAction(_:)))
        }
        
        nameField.addTarget(self, action: #selector(self.textFieldEditChange(_:)), forControlEvents: .EditingChanged)
        editButton.addTarget(self, touchUpInside: #selector(self.edit(_:)))
        saveButton.addTarget(self, touchUpInside: #selector(self.save(_:)))
        restrictSwitch.onTintColor = Color.orange
        muteSwitch.onTintColor = Color.orange
        restrictSwitch.addTarget(self, action: #selector(self.switched(_:)), forControlEvents: .ValueChanged)
        muteSwitch.addTarget(self, action: #selector(self.switched(_:)), forControlEvents: .ValueChanged)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        saveButton.hidden = true
        let wrap = self.wrap
        nameField.text = wrap.name
        muteSwitch.on = wrap.muted
        restrictSwitch.on = !wrap.restricted
        API.preferences(wrap).send({ [weak self] _ in
            self?.muteSwitch.on = wrap.muted
            self?.editSession.muted.originalValue = wrap.muted
            })
        Wrap.notifier().addReceiver(self)
    }
    
    func handleAction(sender: Button) {
        let wrap = self.wrap
        UIAlertController.confirmWrapDeleting(wrap, success: {[weak self] _ in
            self?.userInitiatedDestructiveAction = true
            sender.loading = false
            self?.view.userInteractionEnabled = false
            let deletable = wrap.deletable
            wrap.delete({ _ in
                self?.navigationController?.popToRootViewControllerAnimated(false)
                if (deletable) { Toast.show("delete_wrap_success".ls) }
                sender.loading = false
                }, failure: { [weak self] error -> Void in
                    self?.userInitiatedDestructiveAction = false
                    error?.show()
                    sender.loading = false
                    self?.view.userInteractionEnabled = true
                })
            }, failure: { _ in })
    }
    
    func switched(sender: AnyObject) {
        editSession.muted.changedValue = muteSwitch.on
        if isAdmin {
            editSession.restricted.changedValue = !restrictSwitch.on
        }
    }
    
    func edit(sender: UIButton) {
        if sender.selected {
            editSession.name.reset()
            nameField.resignFirstResponder()
            nameField.text = editSession.name.originalValue
        } else {
            nameField.becomeFirstResponder()
        }
    }
    
    //MARK: UITextFieldHandler
    
    func textFieldEditChange(textfield: UITextField) {
        if let text = textfield.text where text.characters.count > Constants.wrapNameLimit {
            textfield.text = text.substringToIndex(text.startIndex.advancedBy(Constants.wrapNameLimit))
        }
        editSession.name.changedValue = textfield.text?.trim ?? ""
        editButton.selected = editSession.hasChanges ?? false
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func save(sender: AnyObject) {
        if let name = nameField.text?.trim where !name.isEmpty {
            if case let editSession = editSession where editSession.hasChanges == true {
                editSession.apply()
                let wrap = self.wrap
                wrap.update({ _ in
                    if editSession.muted.hasChanges {
                        API.changePreferences(wrap).send({ _ in }, failure: { error in
                            error?.show()
                            editSession.muted.reset()
                        })
                    }
                    }, failure: { error in
                    error?.show()
                    editSession.reset()
                })
            }
        } else {
            Toast.show("wrap_name_cannot_be_blank".ls)
        }
        navigationController?.popViewControllerAnimated(false)
    }
    
    //MARK: EntryNotifying
    
    func notifier(notifier: EntryNotifier, willDeleteEntry entry: Entry) {
        if viewAppeared && !userInitiatedDestructiveAction {
            navigationController?.popToRootViewControllerAnimated(false)
            if !wrap.deletable {
                Toast.showMessageForUnavailableWrap(wrap)
            }
        }
    }
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        if !isAdmin {
            restrictLabel.text = wrap.restricted ? "only_admin_can_add_people".ls : "friends_allowed_to_app_people".ls
        }
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return wrap == entry
    }
    
    func editSession(session: EditSessionProtocol, hasChanges: Bool) {
        saveButton.hidden = editSession.hasChanges == false
    }
}
