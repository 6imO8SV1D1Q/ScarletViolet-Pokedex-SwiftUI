//
//  Nature.swift
//  ScarletViolet-Pokedex-SwiftUI
//
//  Created by Claude on 2025-11-09.
//

import Foundation

/// ポケモンの性格
///
/// 性格によって能力値の補正（1.1倍 or 0.9倍）が適用されます。
/// 5つの性格（hardy, docile, serious, bashful, quirky）は補正なしです。
enum Nature: String, CaseIterable, Codable, Sendable {
    // 攻撃↑
    case lonely   // 防御↓
    case brave    // 素早さ↓
    case adamant  // 特攻↓
    case naughty  // 特防↓

    // 防御↑
    case bold     // 攻撃↓
    case relaxed  // 素早さ↓
    case impish   // 特攻↓
    case lax      // 特防↓

    // 特攻↑
    case modest   // 攻撃↓
    case mild     // 防御↓
    case quiet    // 素早さ↓
    case rash     // 特防↓

    // 特防↑
    case calm     // 攻撃↓
    case gentle   // 防御↓
    case sassy    // 素早さ↓
    case careful  // 特攻↓

    // 素早さ↑
    case timid    // 攻撃↓
    case hasty    // 防御↓
    case jolly    // 特攻↓
    case naive    // 特防↓

    // 補正なし
    case hardy
    case docile
    case serious
    case bashful
    case quirky

    /// 日本語名
    var nameJa: String {
        switch self {
        case .hardy: return "がんばりや"
        case .lonely: return "さみしがり"
        case .brave: return "ゆうかん"
        case .adamant: return "いじっぱり"
        case .naughty: return "やんちゃ"
        case .bold: return "ずぶとい"
        case .docile: return "すなお"
        case .relaxed: return "のんき"
        case .impish: return "わんぱく"
        case .lax: return "のうてんき"
        case .timid: return "おくびょう"
        case .hasty: return "せっかち"
        case .serious: return "まじめ"
        case .jolly: return "ようき"
        case .naive: return "むじゃき"
        case .modest: return "ひかえめ"
        case .mild: return "おっとり"
        case .quiet: return "れいせい"
        case .bashful: return "てれや"
        case .rash: return "うっかりや"
        case .calm: return "おだやか"
        case .gentle: return "おとなしい"
        case .sassy: return "なまいき"
        case .careful: return "しんちょう"
        case .quirky: return "きまぐれ"
        }
    }

    /// 英語名（表示用）
    var nameEn: String {
        rawValue.capitalized
    }

    /// 性格による能力値補正
    ///
    /// - Returns: (上昇する能力, 下降する能力)のタプル。補正なしの場合は両方nil
    var statModifiers: (increased: StatType?, decreased: StatType?) {
        switch self {
        // 攻撃↑
        case .lonely: return (.attack, .defense)
        case .brave: return (.attack, .speed)
        case .adamant: return (.attack, .specialAttack)
        case .naughty: return (.attack, .specialDefense)

        // 防御↑
        case .bold: return (.defense, .attack)
        case .relaxed: return (.defense, .speed)
        case .impish: return (.defense, .specialAttack)
        case .lax: return (.defense, .specialDefense)

        // 特攻↑
        case .modest: return (.specialAttack, .attack)
        case .mild: return (.specialAttack, .defense)
        case .quiet: return (.specialAttack, .speed)
        case .rash: return (.specialAttack, .specialDefense)

        // 特防↑
        case .calm: return (.specialDefense, .attack)
        case .gentle: return (.specialDefense, .defense)
        case .sassy: return (.specialDefense, .speed)
        case .careful: return (.specialDefense, .specialAttack)

        // 素早さ↑
        case .timid: return (.speed, .attack)
        case .hasty: return (.speed, .defense)
        case .jolly: return (.speed, .specialAttack)
        case .naive: return (.speed, .specialDefense)

        // 補正なし
        case .hardy, .docile, .serious, .bashful, .quirky:
            return (nil, nil)
        }
    }

    /// 性格補正倍率を計算
    ///
    /// - Parameter stat: 対象の能力
    /// - Returns: 補正倍率（0.9, 1.0, 1.1のいずれか）
    func multiplier(for stat: StatType) -> Double {
        let (increased, decreased) = statModifiers

        if increased == stat {
            return 1.1
        } else if decreased == stat {
            return 0.9
        } else {
            return 1.0
        }
    }
}

/// 能力値のタイプ（HP以外）
enum StatType: String, Codable, Sendable {
    case attack
    case defense
    case specialAttack
    case specialDefense
    case speed

    var nameJa: String {
        switch self {
        case .attack: return "こうげき"
        case .defense: return "ぼうぎょ"
        case .specialAttack: return "とくこう"
        case .specialDefense: return "とくぼう"
        case .speed: return "すばやさ"
        }
    }

    var nameEn: String {
        switch self {
        case .attack: return "Attack"
        case .defense: return "Defense"
        case .specialAttack: return "Sp. Atk"
        case .specialDefense: return "Sp. Def"
        case .speed: return "Speed"
        }
    }
}
