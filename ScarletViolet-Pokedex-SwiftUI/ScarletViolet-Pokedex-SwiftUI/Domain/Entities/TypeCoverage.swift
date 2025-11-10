//
//  TypeCoverage.swift
//  ScarletViolet-Pokedex-SwiftUI
//
//  Created by Claude on 2025-11-09.
//

import Foundation

/// パーティ全体のタイプ相性分析結果
///
/// パーティの弱点、耐性、無効タイプ、攻撃範囲などを分析した結果を保持します。
struct TypeCoverage: Codable, Hashable, Sendable {
    /// 弱点タイプとその数
    ///
    /// キー: タイプ名（"fire", "water"など）
    /// 値: そのタイプが弱点となるポケモンの数
    var weaknesses: [String: Int]

    /// 耐性タイプとその数
    ///
    /// キー: タイプ名
    /// 値: そのタイプに耐性を持つポケモンの数
    var resistances: [String: Int]

    /// 無効タイプのセット
    ///
    /// パーティ内で完全に無効化できるタイプ
    var immunities: Set<String>

    /// 攻撃範囲カバレッジスコア（0.0〜1.0）
    ///
    /// パーティの技構成がどれだけ多くのタイプをカバーできているかを示すスコア。
    /// 1.0に近いほど多様なタイプをカバーできている。
    var coverageScore: Double

    // MARK: - Initialization

    init(
        weaknesses: [String: Int] = [:],
        resistances: [String: Int] = [:],
        immunities: Set<String> = [],
        coverageScore: Double = 0.0
    ) {
        self.weaknesses = weaknesses
        self.resistances = resistances
        self.immunities = immunities
        self.coverageScore = coverageScore
    }

    /// 空の分析結果
    static var empty: TypeCoverage {
        TypeCoverage()
    }
}
