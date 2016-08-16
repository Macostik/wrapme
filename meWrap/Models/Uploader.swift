//
//  Uploader.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/25/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import CoreData

final class Uploader: EntryNotifying {
    
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
    private lazy var uploadings: [Uploading] = self.prepareUploadings()
    
    let didStart = Notifier<Uploader>()
    let didChange = Notifier<Uploader>()
    let didStop = Notifier<Uploader>()
    
    var isUploading: Bool = false {
        didSet {
            if isUploading != oldValue {
                if isUploading {
                    didStart.notify(self)
                } else {
                    didStop.notify(self)
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
        EntryNotifier.notifierForName(entityName).addReceiver(self)
    }
    
    func finish() {
        if isEmpty && Network.network.reachable {
            for uploader in subuploaders {
                uploader.start()
            }
        }
    }
    
    private func prepareUploadings() -> [Uploading] {
        let contributions = FetchRequest<Contribution>(name: entityName).query("uploading != nil").sort("createdAt", asc:true).execute()
        Logger.log("\(entityName) uploading queue prepared with: \(contributions)")
        return contributions.map({ $0.uploading! })
    }
    
    func start() {
        
        guard Network.network.reachable && Authorization.active else { return }
        
        if isEmpty {
            finish()
        } else {
            for uploading in uploadings where !uploading.inProgress {
                enqueue(uploading, success: nil, failure: nil)
            }
        }
    }
    
    private func _didChange() {
        didChange.notify(self)
        isUploading = !isEmpty
    }
    
    private func _upload(uploading: Uploading, success: ObjectBlock?, failure: FailureBlock?) {
        isUploading = true
        uploading.upload({ [weak self] (object) -> Void in
            self?.remove(uploading)
            success?(object)
            self?._didChange()
            }) { [weak self] (error) -> Void in
                if !(uploading.contribution?.valid ?? false) {
                    self?.remove(uploading)
                }
                failure?(error)
                self?._didChange()
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
            didChange.notify(self)
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
            
            _didChange()
            
            for uploading in removedUploadings {
                if let contribution = uploading.contribution {
                    for uploader in subuploaders {
                        uploader.didRemoveContainer(contribution)
                    }
                }
            }
        }
    }
    
    // MARK: - EntryNotifying
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return entry.valid
    }
    
    func notifier(notifier: EntryNotifier, willDeleteEntry entry: Entry) {
        
        guard let contribution = (entry as? Contribution) else { return }
        
        if let uploading = contribution.uploading, let index = uploadings.indexOf(uploading) {
            uploadings.removeAtIndex(index)
            _didChange()
        }
        
        isUploading = !isEmpty
        
        for uploader in subuploaders {
            uploader.didRemoveContainer(contribution)
        }
    }
}
