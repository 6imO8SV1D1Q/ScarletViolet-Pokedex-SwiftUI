//
//  TeraType.swift
//  ScarletViolet-Pokedex-SwiftUI
//
//  Created by Claude on 2025-11-09.
//

import Foundation
import SwiftUI

/// スカーレット・バイオレットのテラスタイプ定義
///
/// 18通常タイプ + ステラタイプの計19種類
enum TeraType: String, CaseIterable, Codable, Sendable {
    case normal
    case fire
    case water
    case electric
    case grass
    case ice
    case fighting
    case poison
    case ground
    case flying
    case psychic
    case bug
    case rock
    case ghost
    case dragon
    case dark
    case steel
    case fairy
    case stellar  // ステラタイプ（DLC「ゼロの秘宝」追加）

    /// タイプの日本語名
    var nameJa: String {
        switch self {
        case .normal: return "ノーマル"
        case .fire: return "ほのお"
        case .water: return "みず"
        case .electric: return "でんき"
        case .grass: return "くさ"
        case .ice: return "こおり"
        case .fighting: return "かくとう"
        case .poison: return "どく"
        case .ground: return "じめん"
        case .flying: return "ひこう"
        case .psychic: return "エスパー"
        case .bug: return "むし"
        case .rock: return "いわ"
        case .ghost: return "ゴースト"
        case .dragon: return "ドラゴン"
        case .dark: return "あく"
        case .steel: return "はがね"
        case .fairy: return "フェアリー"
        case .stellar: return "ステラ"
        }
    }

    /// タイプの英語名（表示用）
    var nameEn: String {
        switch self {
        case .normal: return "Normal"
        case .fire: return "Fire"
        case .water: return "Water"
        case .electric: return "Electric"
        case .grass: return "Grass"
        case .ice: return "Ice"
        case .fighting: return "Fighting"
        case .poison: return "Poison"
        case .ground: return "Ground"
        case .flying: return "Flying"
        case .psychic: return "Psychic"
        case .bug: return "Bug"
        case .rock: return "Rock"
        case .ghost: return "Ghost"
        case .dragon: return "Dragon"
        case .dark: return "Dark"
        case .steel: return "Steel"
        case .fairy: return "Fairy"
        case .stellar: return "Stellar"
        }
    }

    /// テラスタルのシンボルカラー
    ///
    /// 既存のタイプカラーシステムと互換性を持たせるため、
    /// PokemonTypeColorヘルパーを使用する想定
    var color: Color {
        switch self {
        case .normal: return Color(red: 168/255, green: 168/255, blue: 120/255)
        case .fire: return Color(red: 240/255, green: 128/255, blue: 48/255)
        case .water: return Color(red: 104/255, green: 144/255, blue: 240/255)
        case .electric: return Color(red: 248/255, green: 208/255, blue: 48/255)
        case .grass: return Color(red: 120/255, green: 200/255, blue: 80/255)
        case .ice: return Color(red: 152/255, green: 216/255, blue: 216/255)
        case .fighting: return Color(red: 192/255, green: 48/255, blue: 40/255)
        case .poison: return Color(red: 160/255, green: 64/255, blue: 160/255)
        case .ground: return Color(red: 224/255, green: 192/255, blue: 104/255)
        case .flying: return Color(red: 168/255, green: 144/255, blue: 240/255)
        case .psychic: return Color(red: 248/255, green: 88/255, blue: 136/255)
        case .bug: return Color(red: 168/255, green: 184/255, blue: 32/255)
        case .rock: return Color(red: 184/255, green: 160/255, blue: 56/255)
        case .ghost: return Color(red: 112/255, green: 88/255, blue: 152/255)
        case .dragon: return Color(red: 112/255, green: 56/255, blue: 248/255)
        case .dark: return Color(red: 112/255, green: 88/255, blue: 72/255)
        case .steel: return Color(red: 184/255, green: 184/255, blue: 208/255)
        case .fairy: return Color(red: 238/255, green: 153/255, blue: 172/255)
        case .stellar: return Color(red: 64/255, green: 224/255, blue: 208/255)  // 水色系の特別色
        }
    }

    /// 全テラスタイプのリスト（文字列）
    static var allTypes: [String] {
        TeraType.allCases.map { $0.rawValue }
    }
}
