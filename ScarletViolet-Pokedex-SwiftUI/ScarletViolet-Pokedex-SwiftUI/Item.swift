//
//  Item.swift
//  ScarletViolet-Pokedex-SwiftUI
//
//  Created by 阿部友祐 on 2025/11/09.
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
