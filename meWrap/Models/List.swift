//
//  List.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/8/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

@objc protocol ListEntry: NSObjectProtocol {
    func listSortDate() -> NSDate
    func listEntryEqual(entry: ListEntry) -> Bool
}

@objc protocol ListNotifying {
    optional func listChanged(list: List)
}

class List: Notifier {
    
    var entries = [ListEntry]() {
        didSet {
            didChange()
        }
    }
    
    func add(entry: ListEntry) {
        if !entries.contains({ $0.listEntryEqual(entry) }) {
            entries.append(entry)
            sort()
        }
    }
    
    func addEntries(entries: [ListEntry]) {
        var added = false
        for entry in entries {
            if !self.entries.contains({ $0.listEntryEqual(entry) }) {
                added = true
                self.entries.append(entry)
            }
        }
        if added {
            sort()
        }
    }
    
    func sort() {
        self.entries = self.entries.sort({ $0.listSortDate() > $1.listSortDate() })
    }
    
    func sort(entry: ListEntry) {
        if entries.contains({ $0.listEntryEqual(entry) }) {
            sort()
        } else {
            add(entry)
        }
    }
    
    func remove(entry: ListEntry) {
        if let index = entries.indexOf({ $0.listEntryEqual(entry) }) {
            entries.removeAtIndex(index)
        }
    }
    
    internal func didChange() {
        notify { (receiver) -> Void in
            receiver.listChanged?(self)
        }
    }
    
    subscript(index: Int) -> ListEntry? {
        return (index >= 0 && index < count) ? entries[index] : nil
    }
}

@objc protocol BaseOrderedContainer {
    var count: Int { get }
    func objectAtIndex(index: Int) -> AnyObject
    func tryAt(index: Int) -> AnyObject?
}

extension NSArray: BaseOrderedContainer {
    func tryAt(index: Int) -> AnyObject? {
        return (index >= 0 && index < count) ? self[index] : nil
    }
}

extension List: BaseOrderedContainer {
    var count: Int {
        return entries.count
    }
    func tryAt(index: Int) -> AnyObject? {
        return (index >= 0 && index < count) ? entries[index] : nil
    }
    func objectAtIndex(index: Int) -> AnyObject {
        return entries[index]
    }
}

@objc protocol PaginatedListNotifying: ListNotifying {
    optional func paginatedListDidStartLoading(list: PaginatedList)
    optional func paginatedListDidFinishLoading(list: PaginatedList)
}

class PaginatedList: List {
    
    convenience init(request: PaginatedRequest) {
        self.init()
        self.request = request
    }
    
    convenience init(entries: [ListEntry], request: PaginatedRequest) {
        self.init(request: request)
        self.addEntries(entries)
    }
    
    var completed: Bool = false {
        didSet {
            if completed != oldValue {
                didChange()
            }
        }
    }
    
    var request: PaginatedRequest?
    
    private var loadingTypes = Set<PaginatedRequestType>()
    
    private func addLoadingType(type: PaginatedRequestType) {
        loadingTypes.insert(type)
        if loadingTypes.count == 1 {
            notify({ (receiver) -> Void in
                receiver.paginatedListDidStartLoading?(self)
            })
        }
    }
    
    private func removeLoadingType(type: PaginatedRequestType) {
        loadingTypes.remove(type)
        if loadingTypes.count == 0 {
            notify({ (receiver) -> Void in
                receiver.paginatedListDidFinishLoading?(self)
            })
        }
    }
    
    func fresh(success: ObjectBlock?, failure: FailureBlock?) {
        send(.Fresh, success: success, failure: failure)
    }
    
    func newer(success: ObjectBlock?, failure: FailureBlock?) {
        send(.Newer, success: success, failure: failure)
    }
    
    func older(success: ObjectBlock?, failure: FailureBlock?) {
        send(.Older, success: success, failure: failure)
    }
    
    func send(type: PaginatedRequestType, success: ObjectBlock?, failure: FailureBlock?) {
        if let request = request where !loadingTypes.contains(type) {
            addLoadingType(type)
            RunQueue.fetchQueue.run { [weak self] (finish) -> Void in
                if let list = self {
                    request.type = type
                    list.configureRequest(request)
                    request.send({ (object) -> Void in
                        list.handleResponse(object, type: type)
                        list.removeLoadingType(type)
                        finish()
                        success?(object)
                        }, failure: { (error) -> Void in
                            list.removeLoadingType(type)
                            finish()
                            failure?(error)
                    })
                } else {
                    finish()
                    success?(nil)
                }
            }
        } else {
            failure?(nil)
        }
    }
    
    internal func handleResponse(entries: AnyObject?, type: PaginatedRequestType) {
        if let entries = entries as? [ListEntry] {
            addEntries(entries)
            if entries.isEmpty && type == .Older {
                completed = true
            }
        }
    }
    
    internal func newerPaginationDate() -> NSDate? {
        return entries.first?.listSortDate()
    }
    
    internal func olderPaginationDate() -> NSDate? {
        return entries.last?.listSortDate()
    }
    
    internal func configureRequest(request: PaginatedRequest) {
        if entries.count == 0 {
            request.type = .Fresh
        } else {
            request.newer = newerPaginationDate()
            request.older = olderPaginationDate()
        }
    }
}

extension Entry: ListEntry {
    func listSortDate() -> NSDate {
        return createdAt
    }
    func listEntryEqual(entry: ListEntry) -> Bool {
        return self == (entry as? Entry)
    }
}

extension Wrap {
    override func listSortDate() -> NSDate {
        return updatedAt
    }
}

