//
//  Contribution.swift
//  
//
//  Created by Sergey Maximenko on 10/26/15.
//
//

import Foundation
import CoreData

@objc(Uploading)
class Uploading: Entry {
    
    override class func entityName() -> String {
        return "Uploading"
    }
    
    var inProgress = false
}

@objc(Contribution)
class Contribution: Entry {
    
    override class func entityName() -> String {
        return "Contribution"
    }
    
    class func recentContributions() -> [Contribution] {
        var contributions = [Contribution]()
        let date = NSDate.now().startOfDay()
        let comments = Comment.fetch().query("createdAt > %@ AND contributor != nil", date).execute()
        contributions.appendContentsOf(comments as! [Contribution])
        let candies = Candy.fetch().query("createdAt > %@ AND contributor != nil", date).execute()
        contributions.appendContentsOf(candies as! [Contribution])
        return contributions
    }
    
    class func recentContributions(limit: Int) -> [Contribution] {
        let contributions = recentContributions()
        if contributions.count > limit {
            return Array(contributions[0..<limit])
        } else {
            return contributions
        }
    }
    
    func statusOfAnyUploadingType() -> ContributionStatus {
        if let uploading = uploading {
            if uploading.inProgress {
                return .InProgress
            } else {
                return .Ready
            }
        } else {
            return .Finished
        }
    }
    
    func statusOfUploadingEvent(event: Event) -> ContributionStatus {
        if let uploading = uploading where uploading.type == event.rawValue {
            if uploading.inProgress {
                return .InProgress
            } else {
                return .Ready
            }
        } else {
            return .Finished
        }
    }
    
    var status: ContributionStatus {
        return statusOfUploadingEvent(.Add)
    }
    
    var uploaded: Bool {
        return status == .Finished
    }
    
    var deletable: Bool {
        return contributor?.current ?? false
    }
    
    var canBeUploaded: Bool {
        return true
    }

}
