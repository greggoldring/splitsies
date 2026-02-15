//
//  Item.swift
//  Splitsies
//
//  Created by Gregg Oldring on 2026-02-14.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
