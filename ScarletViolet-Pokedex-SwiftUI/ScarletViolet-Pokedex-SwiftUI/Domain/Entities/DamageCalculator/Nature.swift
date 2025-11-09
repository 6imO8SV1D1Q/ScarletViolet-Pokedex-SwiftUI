//
//  Nature.swift
//  Pokedex
//
//  Created on 2025-11-02.
//

import Foundation

/// ポケモンの性格
enum Nature: String, CaseIterable, Codable {
    // 補正なし（5種類）
    case hardy = "hardy"           // がんばりや
    case docile = "docile"         // すなお
    case serious = "serious"       // まじめ
    case bashful = "bashful"       // てれや
    case quirky = "quirky"         // きまぐれ

    // こうげき↑（5種類）
    case lonely = "lonely"         // さみしがり (こうげき↑ ぼうぎょ↓)
    case brave = "brave"           // ゆうかん (こうげき↑ すばやさ↓)
    case adamant = "adamant"       // いじっぱり (こうげき↑ とくこう↓)
    case naughty = "naughty"       // やんちゃ (こうげき↑ とくぼう↓)

    // ぼうぎょ↑（5種類）
    case bold = "bold"             // ずぶとい (ぼうぎょ↑ こうげき↓)
    case relaxed = "relaxed"       // のんき (ぼうぎょ↑ すばやさ↓)
    case impish = "impish"         // わんぱく (ぼうぎょ↑ とくこう↓)
    case lax = "lax"               // のうてんき (ぼうぎょ↑ とくぼう↓)

    // とくこう↑（5種類）
    case modest = "modest"         // ひかえめ (とくこう↑ こうげき↓)
    case mild = "mild"             // おっとり (とくこう↑ ぼうぎょ↓)
    case quiet = "quiet"           // れいせい (とくこう↑ すばやさ↓)
    case rash = "rash"             // うっかりや (とくこう↑ とくぼう↓)

    // とくぼう↑（5種類）
    case calm = "calm"             // おだやか (とくぼう↑ こうげき↓)
    case gentle = "gentle"         // おとなしい (とくぼう↑ ぼうぎょ↓)
    case sassy = "sassy"           // なまいき (とくぼう↑ すばやさ↓)
    case careful = "careful"       // しんちょう (とくぼう↑ とくこう↓)

    // すばやさ↑（5種類）
    case timid = "timid"           // おくびょう (すばやさ↑ こうげき↓)
    case hasty = "hasty"           // せっかち (すばやさ↑ ぼうぎょ↓)
    case jolly = "jolly"           // ようき (すばやさ↑ とくこう↓)
    case naive = "naive"           // むじゃき (すばやさ↑ とくぼう↓)

    /// 日本語名
    var displayName: String {
        switch self {
        case .hardy: return "がんばりや"
        case .docile: return "すなお"
        case .serious: return "まじめ"
        case .bashful: return "てれや"
        case .quirky: return "きまぐれ"
        case .lonely: return "さみしがり"
        case .brave: return "ゆうかん"
        case .adamant: return "いじっぱり"
        case .naughty: return "やんちゃ"
        case .bold: return "ずぶとい"
        case .relaxed: return "のんき"
        case .impish: return "わんぱく"
        case .lax: return "のうてんき"
        case .modest: return "ひかえめ"
        case .mild: return "おっとり"
        case .quiet: return "れいせい"
        case .rash: return "うっかりや"
        case .calm: return "おだやか"
        case .gentle: return "おとなしい"
        case .sassy: return "なまいき"
        case .careful: return "しんちょう"
        case .timid: return "おくびょう"
        case .hasty: return "せっかち"
        case .jolly: return "ようき"
        case .naive: return "むじゃき"
        }
    }

    /// 記号表記（例: A↑D↓、C↑A↓、-）
    var shortNotation: String {
        let stats = ["attack", "defense", "special-attack", "special-defense", "speed"]
        var increased: String = ""
        var decreased: String = ""

        for stat in stats {
            let mod = modifier(for: stat)
            if mod > 1.0 {
                increased = statShort(stat)
            } else if mod < 1.0 {
                decreased = statShort(stat)
            }
        }

        if increased.isEmpty && decreased.isEmpty {
            return "-"
        }
        return "\(increased)↑\(decreased)↓"
    }

    /// 上昇補正のみの日本語表記（例: こうげき↑、とくこう↑、-）
    var simpleNotation: String {
        let stats = ["attack", "defense", "special-attack", "special-defense", "speed"]

        for stat in stats {
            let mod = modifier(for: stat)
            if mod > 1.0 {
                return "\(statNameJapanese(stat))↑"
            }
        }

        return "-"
    }

    /// ステータスの短縮表記
    private func statShort(_ stat: String) -> String {
        switch stat {
        case "attack": return "A"
        case "defense": return "B"
        case "special-attack": return "C"
        case "special-defense": return "D"
        case "speed": return "S"
        default: return "?"
        }
    }

    /// ステータス名の日本語表記
    private func statNameJapanese(_ stat: String) -> String {
        switch stat {
        case "attack": return "こうげき"
        case "defense": return "ぼうぎょ"
        case "special-attack": return "とくこう"
        case "special-defense": return "とくぼう"
        case "speed": return "すばやさ"
        default: return stat
        }
    }

    /// 補正値（ステータスごと）
    /// - Parameter stat: ステータス名（"attack", "defense", "special-attack", "special-defense", "speed"）
    /// - Returns: 補正倍率（0.9, 1.0, 1.1）
    func modifier(for stat: String) -> Double {
        switch self {
        // 補正なし
        case .hardy, .docile, .serious, .bashful, .quirky:
            return 1.0

        // こうげき↑
        case .lonely:
            if stat == "attack" { return 1.1 }
            if stat == "defense" { return 0.9 }
            return 1.0
        case .brave:
            if stat == "attack" { return 1.1 }
            if stat == "speed" { return 0.9 }
            return 1.0
        case .adamant:
            if stat == "attack" { return 1.1 }
            if stat == "special-attack" { return 0.9 }
            return 1.0
        case .naughty:
            if stat == "attack" { return 1.1 }
            if stat == "special-defense" { return 0.9 }
            return 1.0

        // ぼうぎょ↑
        case .bold:
            if stat == "defense" { return 1.1 }
            if stat == "attack" { return 0.9 }
            return 1.0
        case .relaxed:
            if stat == "defense" { return 1.1 }
            if stat == "speed" { return 0.9 }
            return 1.0
        case .impish:
            if stat == "defense" { return 1.1 }
            if stat == "special-attack" { return 0.9 }
            return 1.0
        case .lax:
            if stat == "defense" { return 1.1 }
            if stat == "special-defense" { return 0.9 }
            return 1.0

        // とくこう↑
        case .modest:
            if stat == "special-attack" { return 1.1 }
            if stat == "attack" { return 0.9 }
            return 1.0
        case .mild:
            if stat == "special-attack" { return 1.1 }
            if stat == "defense" { return 0.9 }
            return 1.0
        case .quiet:
            if stat == "special-attack" { return 1.1 }
            if stat == "speed" { return 0.9 }
            return 1.0
        case .rash:
            if stat == "special-attack" { return 1.1 }
            if stat == "special-defense" { return 0.9 }
            return 1.0

        // とくぼう↑
        case .calm:
            if stat == "special-defense" { return 1.1 }
            if stat == "attack" { return 0.9 }
            return 1.0
        case .gentle:
            if stat == "special-defense" { return 1.1 }
            if stat == "defense" { return 0.9 }
            return 1.0
        case .sassy:
            if stat == "special-defense" { return 1.1 }
            if stat == "speed" { return 0.9 }
            return 1.0
        case .careful:
            if stat == "special-defense" { return 1.1 }
            if stat == "special-attack" { return 0.9 }
            return 1.0

        // すばやさ↑
        case .timid:
            if stat == "speed" { return 1.1 }
            if stat == "attack" { return 0.9 }
            return 1.0
        case .hasty:
            if stat == "speed" { return 1.1 }
            if stat == "defense" { return 0.9 }
            return 1.0
        case .jolly:
            if stat == "speed" { return 1.1 }
            if stat == "special-attack" { return 0.9 }
            return 1.0
        case .naive:
            if stat == "speed" { return 1.1 }
            if stat == "special-defense" { return 0.9 }
            return 1.0
        }
    }
}
