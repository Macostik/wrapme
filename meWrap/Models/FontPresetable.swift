//
//  FontPresetter.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/20/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

protocol FontPresetable: class {
    var presetableFont: UIFont? { get set }
    var contentSizeCategoryObserver: NotificationObserver? { get set }
}

extension FontPresetable {
    
    func makePresetable(preset: Font) {
        presetableFont = presetableFont?.fontWithPreset(preset)
        contentSizeCategoryObserver = NotificationObserver.contentSizeCategoryObserver({ [weak self] (_) in
            if let presetable = self {
                presetable.presetableFont = presetable.presetableFont?.fontWithPreset(preset)
            }
        })
    }
    
    func makePresetable(presetString: String?) {
        if let presetString = presetString, let preset = Font(rawValue: presetString) {
            makePresetable(preset)
        }
    }
}
