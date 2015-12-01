//
//  Keys.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/1/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

struct Keys {
    
    struct URL {
        static let Original = "original"
        static let Large = "large"
        static let Medium = "medium"
        static let Small = "small"
        static let MediumSQ = "medium_sq"
        static let SmallSQ = "small_sq"
        static let XLarge = "xlarge"
    }
    
    struct UID {
        static let Wrap = "wrap_uid"
        static let Candy = "candy_uid"
        static let Message = "chat_uid"
        static let Comment = "comment_uid"
        static let User = "user_uid"
        static let Upload = "upload_uid"
        static let Device = "device_uid"
        static let UID = "uid"
    }
    
    static let CandyType = "candy_type"
    static let Comments = "comments"
    static let MediaURLs = "media_urls"
    static let ImageURLs = "image_urls"
    static let VideoURLs = "video_urls"
    static let AvatarURLs = "avatar_urls"
    static let User = "user"
    static let Wrap = "wrap"
    static let Candy = "candy"
    static let Message = "chat"
    static let Comment = "comment"
    static let Creator = "creator"
    static let Content = "content"
    static let Contributor = "contributor"
    static let LastTouchedAt = "last_touched_at_in_epoch"
    static let ContributedAt = "contributed_at_in_epoch"
    static let FullPhoneNumber = "full_phone_number"
    static let SignInCount = "sign_in_count"
    static let Name = "name"
    static let Email = "email"
    static let UnconfirmedEmail = "unconfirmed_email"
    static let Confirmed = "confirmed"
    static let Contributors = "contributors"
    static let Candies = "candies"
    static let Wraps = "wraps"
    static let Devices = "devices"
    static let CountryCode = "country_calling_code"
    static let Phone = "phone_number"
    static let Password = "password"
    static let CommentCount = "comment_count"
    static let Editor = "editor"
    static let EditedAt = "edited_at_in_epoch"
    static let Preference = "wrap_preference"
    static let ChatNotifiable = "notify_when_chat_addition"
    static let CandyNotifiable = "notify_when_image_candy_addition"
    static let CandyViolation = "violation_code"
}