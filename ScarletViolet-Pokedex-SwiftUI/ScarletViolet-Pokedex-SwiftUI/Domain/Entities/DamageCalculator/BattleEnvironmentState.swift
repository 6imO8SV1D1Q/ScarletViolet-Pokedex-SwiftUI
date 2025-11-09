//
//  BattleEnvironmentState.swift
//  Pokedex
//
//  Created on 2025-11-01.
//

import Foundation

/// バトル環境の状態
struct BattleEnvironmentState: Equatable, Codable {
    /// 天候
    var weather: WeatherCondition?

    /// フィールド
    var terrain: TerrainField?

    /// 壁効果
    var screen: ScreenEffect?

    /// デフォルト値でイニシャライズ
    init(
        weather: WeatherCondition? = nil,
        terrain: TerrainField? = nil,
        screen: ScreenEffect? = nil
    ) {
        self.weather = weather
        self.terrain = terrain
        self.screen = screen
    }
}

// MARK: - Weather Condition

/// 天候
enum WeatherCondition: String, Codable, CaseIterable, Identifiable {
    case none = "none"
    case sun = "sun"
    case rain = "rain"
    case sandstorm = "sandstorm"
    case snow = "snow"

    var id: String { rawValue }

    var displayName: String {
        let key = "weather.\(rawValue)"
        return NSLocalizedString(key, comment: "")
    }
}

// MARK: - Terrain Field

/// フィールド
enum TerrainField: String, Codable, CaseIterable, Identifiable {
    case none = "none"
    case electric = "electric"
    case grassy = "grassy"
    case misty = "misty"
    case psychic = "psychic"

    var id: String { rawValue }

    var displayName: String {
        let key = "terrain.\(rawValue)"
        return NSLocalizedString(key, comment: "")
    }
}

// MARK: - Screen Effect

/// 壁効果
enum ScreenEffect: String, Codable, CaseIterable, Identifiable {
    case none = "none"
    case reflect = "reflect"
    case lightScreen = "light_screen"
    case auroraVeil = "aurora_veil"

    var id: String { rawValue }

    var displayName: String {
        let key = "screen.\(rawValue)"
        return NSLocalizedString(key, comment: "")
    }

    /// 防御側のダメージ軽減倍率
    /// - Parameters:
    ///   - isDouble: ダブルバトルか
    ///   - isPhysical: 物理技か
    /// - Returns: 倍率（0.5 = 半減、1.0 = 効果なし）
    func damageReduction(isDouble: Bool, isPhysical: Bool) -> Double {
        switch self {
        case .none:
            return 1.0
        case .reflect:
            return isPhysical ? (isDouble ? 2.0/3.0 : 0.5) : 1.0
        case .lightScreen:
            return !isPhysical ? (isDouble ? 2.0/3.0 : 0.5) : 1.0
        case .auroraVeil:
            return isDouble ? 2.0/3.0 : 0.5
        }
    }
}
