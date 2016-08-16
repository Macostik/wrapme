//
//  FontPresetter.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/20/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

final class FontPresetter: Notifier<Void> {
    
    static let presetter: FontPresetter = {
        let presetter = FontPresetter()
        NSNotificationCenter.defaultCenter().addObserver(presetter, selector: #selector(presetter.contentSizeCategoryDidChange), name: UIContentSizeCategoryDidChangeNotification, object: nil)
        return presetter
    }()
    
    @objc private func contentSizeCategoryDidChange() {
        notify()
    }
}

protocol FontPresetable: class {
    var presetableFont: UIFont? { get set }
}

extension FontPresetable {
    
    func makePresetable(preset: Font) {
        presetableFont = presetableFont?.fontWithPreset(preset)
        FontPresetter.presetter.subscribe(self) { [unowned self] (value) in
            self.presetableFont = self.presetableFont?.fontWithPreset(preset)
        }
    }
    
    func makePresetable(presetString: String?) {
        if let presetString = presetString, let preset = Font(rawValue: presetString) {
            makePresetable(preset)
        }
    }
}
