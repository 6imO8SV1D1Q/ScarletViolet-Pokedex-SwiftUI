//
//  DamageCalculationResult.swift
//  Pokedex
//
//  Created on 2025-11-01.
//

import Foundation

/// ダメージ計算結果
struct DamageCalculationResult: Equatable {
    /// 最小ダメージ
    let minDamage: Int

    /// 最大ダメージ
    let maxDamage: Int

    /// 全16通りのダメージ値
    let damageRange: [Int]

    /// 撃破確率（0.0 ~ 1.0）
    let koChance: Double

    /// 確定数（何発で倒せるか）
    let hitsToKO: Int

    /// 防御側の最大HP
    let defenderMaxHP: Int

    /// 計算に使用した各種倍率
    let modifiers: DamageModifiers

    /// 2ターン連続での撃破確率（nil = 計算していない）
    let twoTurnKOChance: Double?

    /// 平均ダメージ
    let averageDamage: Double
}

/// ダメージ計算に使用した倍率
struct DamageModifiers: Equatable {
    /// タイプ一致補正（STAB）
    let stab: Double

    /// タイプ相性倍率
    let typeEffectiveness: Double

    /// 天候補正
    let weather: Double

    /// フィールド補正
    let terrain: Double

    /// 壁補正
    let screen: Double

    /// アイテム補正
    let item: Double

    /// 特性補正
    let ability: Double

    /// その他補正
    let other: Double

    /// 最終的な総合倍率
    var total: Double {
        stab * typeEffectiveness * weather * terrain * screen * item * ability * other
    }
}

// MARK: - Multi-Turn Damage Calculation

/// 1ターン分のダメージ計算結果
struct TurnDamageResult: Equatable {
    /// ターン番号（1始まり）
    let turnNumber: Int

    /// 使用した技のID
    let moveId: Int

    /// 技名
    let moveName: String

    /// ダメージ計算結果
    let damageResult: DamageCalculationResult
}

/// 複数ターンのダメージ計算結果
struct MultiTurnDamageResult: Equatable {
    /// 各ターンの結果
    let turns: [TurnDamageResult]

    /// 各ターン終了時点での撃破確率（累積）
    let cumulativeKOProbabilities: [Double]

    /// 防御側の最大HP
    let defenderMaxHP: Int

    /// 全ターンの累積ダメージ範囲（最小・最大）
    var totalDamageRange: (min: Int, max: Int) {
        let minTotal = turns.map { $0.damageResult.minDamage }.reduce(0, +)
        let maxTotal = turns.map { $0.damageResult.maxDamage }.reduce(0, +)
        return (minTotal, maxTotal)
    }
}
