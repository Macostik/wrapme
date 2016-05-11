//
//  Uploader.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/25/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import CoreData

@objc protocol UploaderNotifying {
    optional func uploaderDidStart(uploader: Uploader)
    optional func uploaderDidChange(uploader: Uploader)
    optional func uploaderDidStop(uploader: Uploader)
}

class Uploader: Notifier {
    
    static let wrapUploader = Uploader(entityName: Wrap.entityName(), subuploaders: [candyUploader, messageUploader], limit: 3)
    
    static let messageUploader = Uploader(entityName: Message.entityName(), subuploaders: [], limit: 1)
    
    static let candyUploader = Uploader(entityName: Candy.entityName(), subuploaders: [commentUploader], limit: 3)
    
    static let commentUploader = Uploader(entityName: Comment.entityName(), subuploaders: [], limit: 3)
    
    weak var parentUploader: Uploader?
    
    private var subuploaders: [Uploader] {
        didSet {
            for uploader in subuploaders {
                uploader.parentUploader = self
            }
        }
    }
    private var limit: Int
    var entityName: String
    
    private var runQueue = RunQueue()
    private var uploadings = [Uploading]()
    
    var isUploading: Bool = false {
        didSet {
            if isUploading != oldValue {
                if isUploading {
                    notify { $0.uploaderDidStart?(self) }
                } else {
                    notify { $0.uploaderDidStop?(self) }
                }
            }
        }
    }
    
    var count: Int { return uploadings.count }
    
    var isEmpty: Bool { return count == 0 }
    
    required init(entityName: String, subuploaders: [Uploader], limit: Int) {
        self.entityName = entityName
        self.subuploaders = subuploaders
        self.limit = limit
        self.runQueue.limit = limit
        super.init()
        EntryNotifier.notifierForName(entityName).addReceiver(self)
    }
    
    func finish() {
        if isEmpty && Network.sharedNetwork.reachable {
            for uploader in subuploaders {
                uploader.start()
            }
        }
    }
    
    private func prepare() {
        let contributions = FetchRequest<Contribution>(name: entityName).query("uploading != nil").sort("createdAt", asc:true).execute()
        uploadings = contributions.map({ $0.uploading! })
        Logger.log("\(entityName) uploading queue prepared with: \(contributions)")
        for uploader in subuploaders {
            uploader.prepare()
        }
    }
    
    func start() {
        
        prepare()
        
        guard Network.sharedNetwork.reachable && Authorization.active else { return }
        
        if isEmpty {
            finish()
        } else {
            for uploading in uploadings where !uploading.inProgress {
                enqueue(uploading, success: nil, failure: nil)
            }
        }
    }
    
    private func didChange() {
        notify { $0.uploaderDidChange?(self) }
        isUploading = !isEmpty
    }
    
    private func _upload(uploading: Uploading, success: ObjectBlock?, failure: FailureBlock?) {
        isUploading = true
        uploading.upload({ [weak self] (object) -> Void in
            self?.remove(uploading)
            success?(object)
            self?.didChange()
            }) { [weak self] (error) -> Void in
                if !(uploading.contribution?.valid ?? false) {
                    self?.remove(uploading)
                }
                failure?(error)
                self?.didChange()
        }
    }
    
    private func enqueue(uploading: Uploading, success: ObjectBlock?, failure: FailureBlock?) {
        if let parentUploader = parentUploader where !parentUploader.isEmpty {
            if !parentUploader.isUploading {
                parentUploader.start()
            }
            failure?(NSError(message: "Parent items are uploading..."))
            return
        }
        runQueue.didFinish = finish
        runQueue.run { [weak self] (finish) -> Void in
            self?._upload(uploading, success: { (object) -> Void in
                finish()
                success?(object)
                }, failure: { (error) -> Void in
                    finish()
                    failure?(error)
            })
        }
    }
    
    private func add(uploading: Uploading) {
        if !uploadings.contains(uploading) {
            uploadings.append(uploading)
            notify { $0.uploaderDidChange?(self) }
        }
    }
    
    private func remove(uploading: Uploading) {
        if let index = uploadings.indexOf(uploading) {
            uploadings.removeAtIndex(index)
        }
    }
    
    func upload(uploading: Uploading, success: ObjectBlock? = nil, failure: FailureBlock? = nil) {
        add(uploading)
        enqueue(uploading, success: success, failure: failure)
    }
    
    private func didRemoveContainer(container: Entry) {
        var removedUploadings = [Uploading]()
        for uploading in uploadings {
            if uploading.contribution?.container == container {
                uploading.inProgress = false
                removedUploadings.append(uploading)
            }
        }
        if removedUploadings.count > 0 {
            
            for uploading in removedUploadings {
                if let index = uploadings.indexOf(uploading) {
                    uploadings.removeAtIndex(index)
                }
            }
            
            didChange()
            
            for uploading in removedUploadings {
                if let contribution = uploading.contribution {
                    for uploader in subuploaders {
                        uploader.didRemoveContainer(contribution)
                    }
                }
            }
        }
    }
}

extension Uploader: EntryNotifying {
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return entry.valid
    }
    
    func notifier(notifier: EntryNotifier, willDeleteEntry entry: Entry) {
        
        guard let contribution = (entry as? Contribution) else { return }
        
        if let uploading = contribution.uploading, let index = uploadings.indexOf(uploading) {
            uploadings.removeAtIndex(index)
            didChange()
        }
        
        isUploading = !isEmpty
        
        for uploader in subuploaders {
            uploader.didRemoveContainer(contribution)
        }
    }
}
