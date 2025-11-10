//
//  StatValues.swift
//  ScarletViolet-Pokedex-SwiftUI
//
//  Created by Claude on 2025-11-09.
//

import Foundation

/// ポケモンの能力値（HP、攻撃、防御、特攻、特防、素早さ）を保持する構造体
///
/// 個体値（IV）、努力値（EV）、実数値などに使用されます。
struct StatValues: Codable, Hashable, Sendable {
    var hp: Int
    var attack: Int
    var defense: Int
    var specialAttack: Int
    var specialDefense: Int
    var speed: Int

    /// 全ステータスの合計値
    var total: Int {
        hp + attack + defense + specialAttack + specialDefense + speed
    }

    // MARK: - Presets

    /// 最大努力値（各252）
    static var maxEVs: StatValues {
        StatValues(
            hp: 252,
            attack: 252,
            defense: 252,
            specialAttack: 252,
            specialDefense: 252,
            speed: 252
        )
    }

    /// 最大個体値（各31）
    static var maxIVs: StatValues {
        StatValues(
            hp: 31,
            attack: 31,
            defense: 31,
            specialAttack: 31,
            specialDefense: 31,
            speed: 31
        )
    }

    /// ゼロ値
    static var zero: StatValues {
        StatValues(
            hp: 0,
            attack: 0,
            defense: 0,
            specialAttack: 0,
            specialDefense: 0,
            speed: 0
        )
    }

    // MARK: - Initialization

    init(hp: Int, attack: Int, defense: Int, specialAttack: Int, specialDefense: Int, speed: Int) {
        self.hp = hp
        self.attack = attack
        self.defense = defense
        self.specialAttack = specialAttack
        self.specialDefense = specialDefense
        self.speed = speed
    }
}
