//
//  meWrapTests.swift
//  meWrapTests
//
//  Created by Sergey Maximenko on 4/28/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Quick
import Nimble
@testable import meWrap

class EntryContextSpec: QuickSpec {
    
    override func spec() {
        describe("insert") {
            
            var count: Int!
            
            beforeEach({ 
                count = FetchRequest<Entry>().count()
            })
            
            it("simple insert") {
                let uids = [GUID(),GUID(),GUID(),GUID(),GUID()]
                let descriptors = Set(uids.map({ EntryDescriptor(name: "Entry", uid: $0, locuid: nil) }))
                EntryContext.sharedContext.fetchEntries(descriptors)
                expect(FetchRequest<Entry>().count() - count).to(equal(uids.count))
                for uid in uids {
                    expect(EntryContext.sharedContext.cachedEntries.objectForKey(uid) == nil).to(equal(false))
                    if let entry = Entry.entry(uid) {
                        EntryContext.sharedContext.deleteEntry(entry)
                    }
                }
                expect(FetchRequest<Entry>().count() - count).to(equal(0))
            }
            
            it("upload_uid insert") {
                let locuids = [GUID(),GUID(),GUID(),GUID(),GUID()]
                for locuid in locuids {
                    let entry = EntryContext.sharedContext.insertEntry("Entry")!
                    entry.uid = locuid
                    entry.locuid = locuid
                }
                expect(FetchRequest<Entry>().count() - count).to(equal(locuids.count))
                
                let uids = [GUID(),GUID(),GUID(),GUID(),GUID()]
                let descriptors = Set(uids.map({ EntryDescriptor(name: "Entry", uid: $0, locuid: locuids[uids.indexOf($0)!]) }))
                EntryContext.sharedContext.fetchEntries(descriptors)
                expect(FetchRequest<Entry>().count() - count).to(equal(uids.count))
                for uid in uids {
                    expect(EntryContext.sharedContext.cachedEntries.objectForKey(uid) == nil).to(equal(false))
                    if let entry = Entry.entry(uid) {
                        EntryContext.sharedContext.deleteEntry(entry)
                    }
                }
                expect(FetchRequest<Entry>().count() - count).to(equal(0))
            }
            
            it("upload_uid insert without prefetching") {
                let locuids = [GUID(),GUID(),GUID(),GUID(),GUID()]
                for locuid in locuids {
                    let entry = EntryContext.sharedContext.insertEntry("Entry")!
                    entry.uid = locuid
                    entry.locuid = locuid
                }
                expect(FetchRequest<Entry>().count() - count).to(equal(locuids.count))
                let uids = [GUID(),GUID(),GUID(),GUID(),GUID()]
                for uid in uids {
                    if let entry = Entry.entry(uid, locuid: locuids[uids.indexOf(uid)!], allowInsert: false) {
                        expect(EntryContext.sharedContext.cachedEntries.objectForKey(uid) == nil).to(equal(false))
                        EntryContext.sharedContext.deleteEntry(entry)
                    }
                }
                expect(FetchRequest<Entry>().count() - count).to(equal(0))
            }
            
            it("comment insert") {
                let comment: Comment = Comment.entry()
                expect(FetchRequest<Entry>().count() - count).to(equal(1))
                if let entry = Comment.entry(comment.uid) {
                    EntryContext.sharedContext.deleteEntry(entry)
                }
                expect(FetchRequest<Entry>().count() - count).to(equal(0))
            }
            
            it("finding entry by locuid") {
                let entry1: Entry = Entry.entry()
                entry1.locuid = entry1.uid
                expect(FetchRequest<Entry>().count() - count).to(equal(1))
                if let entry = Entry.entry(GUID(), locuid: entry1.locuid) {
                    expect(entry).to(equal(entry1))
                    EntryContext.sharedContext.deleteEntry(entry)
                }
                expect(FetchRequest<Entry>().count() - count).to(equal(0))
            }
            
            it("finding entry by locuid") {
                let entry1: Entry = Entry.entry()
                entry1.locuid = entry1.uid
                expect(FetchRequest<Entry>().count() - count).to(equal(1))
                if let entry = Entry.entry(GUID(), locuid: entry1.locuid) {
                    expect(entry).to(equal(entry1))
                    EntryContext.sharedContext.deleteEntry(entry)
                }
                expect(FetchRequest<Entry>().count() - count).to(equal(0))
            }
        }
    }
}
