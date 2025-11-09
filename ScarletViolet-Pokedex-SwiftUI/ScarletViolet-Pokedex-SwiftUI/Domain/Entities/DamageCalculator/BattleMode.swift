//
//  BattleMode.swift
//  Pokedex
//
//  Created on 2025-11-01.
//

import Foundation

/// バトルモード
enum BattleMode: String, Codable, CaseIterable, Identifiable {
    case single = "single"
    case double = "double"

    var id: String { rawValue }

    /// 表示名（多言語対応）
    var displayName: String {
        let key = "battle_mode.\(rawValue)"
        return NSLocalizedString(key, comment: "")
    }

    /// 範囲技の威力倍率
    var spreadMovePowerMultiplier: Double {
        switch self {
        case .single:
            return 1.0
        case .double:
            return 0.75  // ダブルバトルでは範囲技は0.75倍
        }
    }
}
