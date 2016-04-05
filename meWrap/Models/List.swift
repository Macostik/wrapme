//
//  List.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/8/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

protocol ListEntry {
    func listSort(entry: Self) -> Bool
    func listSortDate() -> NSDate
    func listEntryEqual(entry: Self) -> Bool
}

protocol ListNotifying {
    func listChanged<T: ListEntry>(list: List<T>)
}

class List<T: ListEntry>: Notifier {
    
    var entries = [T]()
    
    internal func _add(entry: T) -> Bool {
        if !entries.contains({ $0.listEntryEqual(entry) }) {
            entries.append(entry)
            return true
        } else {
            return false
        }
    }
    
    func add(entry: T) {
        if _add(entry) {
            sort()
        }
    }
    
    func addEntries(entries: [T]) {
        let count = self.entries.count
        for entry in entries {
            _add(entry)
        }
        if count != self.entries.count {
            sort()
        }
    }
    
    func sort() {
        entries = entries.sort({ $0.listSort($1) })
        didChange()
    }
    
    func sort(entry: T) {
        _add(entry)
        sort()
    }
    
    func remove(entry: T) {
        if let index = entries.indexOf({ $0.listEntryEqual(entry) }) {
            entries.removeAtIndex(index)
        }
    }
    
    internal func didChange() {
        notify { ($0 as? ListNotifying)?.listChanged(self) }
    }
    
    subscript(index: Int) -> T? {
        return (index >= 0 && index < count) ? entries[index] : nil
    }
}

protocol BaseOrderedContainer {
    associatedtype ElementType
    var count: Int { get }
    subscript (safe index: Int) -> ElementType? { get }
}

extension Array: BaseOrderedContainer {}

extension List: BaseOrderedContainer {
    var count: Int { return entries.count }
    subscript (safe index: Int) -> T? {
        return entries[safe: index]
    }
}

protocol PaginatedListNotifying: ListNotifying {
    func paginatedListDidStartLoading<T: ListEntry>(list: PaginatedList<T>)
    func paginatedListDidFinishLoading<T: ListEntry>(list: PaginatedList<T>)
}

extension PaginatedListNotifying {
    func paginatedListDidStartLoading<T: ListEntry>(list: PaginatedList<T>) {}
    func paginatedListDidFinishLoading<T: ListEntry>(list: PaginatedList<T>) {}
}

protocol PaginatedListProtocol: BaseOrderedContainer {
    associatedtype PaginatedEntryType
    func fresh(success: ([PaginatedEntryType] -> ())?, failure: FailureBlock?)
    func newer(success: ([PaginatedEntryType] -> ())?, failure: FailureBlock?)
    func older(success: ([PaginatedEntryType] -> ())?, failure: FailureBlock?)
    var completed: Bool { get set }
    func addReceiver(receiver: NSObject?)
}

class PaginatedList<T: ListEntry>: List<T>, PaginatedListProtocol {
    
    convenience init(request: PaginatedRequest<[T]>) {
        self.init()
        self.request = request
    }
    
    convenience init(entries: [T], request: PaginatedRequest<[T]>) {
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
    
    var request: PaginatedRequest<[T]>?
    
    private var loadingTypes = Set<PaginatedRequestType>()
    
    private func addLoadingType(type: PaginatedRequestType) {
        loadingTypes.insert(type)
        if loadingTypes.count == 1 {
            notify({ ($0 as? PaginatedListNotifying)?.paginatedListDidStartLoading(self) })
        }
    }
    
    private func removeLoadingType(type: PaginatedRequestType) {
        loadingTypes.remove(type)
        if loadingTypes.count == 0 {
            notify({ ($0 as? PaginatedListNotifying)?.paginatedListDidFinishLoading(self) })
        }
    }
    
    func fresh(success: ([T] -> ())?, failure: FailureBlock?) {
        send(.Fresh, success: success, failure: failure)
    }
    
    func newer(success: ([T] -> ())?, failure: FailureBlock?) {
        send(.Newer, success: success, failure: failure)
    }
    
    func older(success: ([T] -> ())?, failure: FailureBlock?) {
        send(.Older, success: success, failure: failure)
    }
    
    func send(type: PaginatedRequestType, success: ([T] -> ())?, failure: FailureBlock?) {
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
                    failure?(nil)
                }
            }
        } else {
            failure?(nil)
        }
    }
    
    internal func handleResponse(entries: [T], type: PaginatedRequestType) {
        if entries.isEmpty {
            if type == .Older {
                completed = true
            } else {
                didChange()
            }
        } else {
            addEntries(entries)
        }
    }
    
    internal func newerPaginationDate() -> NSDate? {
        let dates = entries.map({ (entry) -> NSDate in return entry.listSortDate() })
        return dates.maxElement({ $0 < $1 })
    }
    
    internal func olderPaginationDate() -> NSDate? {
        let dates = entries.map({ (entry) -> NSDate in return entry.listSortDate() })
        return dates.maxElement({ $0 > $1 })
    }
    
    internal func configureRequest(request: PaginatedRequest<[T]>) {
        if entries.count == 0 {
            request.type = .Fresh
        } else {
            request.newer = newerPaginationDate()
            request.older = olderPaginationDate()
        }
    }
}

extension ListEntry where Self: Wrap {
    
    func listSort(wrap: Wrap) -> Bool {
        if wrap.liveBroadcasts.count > 0 {
            if liveBroadcasts.count > 0 {
                return name < wrap.name
            } else {
                return false
            }
        } else {
            if liveBroadcasts.count > 0 {
                return true
            } else {
                return updatedAt > wrap.updatedAt
            }
        }
    }
    
    func listSortDate() -> NSDate {
        return updatedAt
    }
}

extension Entry: ListEntry {
    func listSort(entry: Entry) -> Bool {
        return listSortDate() > entry.listSortDate()
    }
    func listSortDate() -> NSDate {
        return createdAt
    }
    func listEntryEqual(entry: Entry) -> Bool {
        return self == entry
    }
}

